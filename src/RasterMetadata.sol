// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Layer} from "./interfaces/Structs.sol";
import {
    UnsupportedMetadata,
    AlreadyCreated,
    LayerNotExisted,
    LayerOutOfBoundary,
    InvalidDrawing
} from "./interfaces/Errors.sol";
import {ICopyright} from "./interfaces/ICopyright.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {ERC165} from "./libraries/ERC165.sol";
import {SafeCast} from "./libraries/SafeCast.sol";
import {RasterEngine, Rotate, Flip} from "./utils/RasterEngine.sol";
import {RasterRenderer} from "./utils/RasterRenderer.sol";

struct Meta {
    uint256 width;
    uint256 height;
    RasterEngine.Palette palette;
    Layer[] layers;
    uint256[] ingredients;
    mapping(uint256 => uint256) ingredientAmountOf;
    bytes drawingLayer;
}

contract RasterMetadata is IMetadata, ERC165 {
    using RasterEngine for RasterEngine.Palette;
    using RasterEngine for RasterEngine.Frame;

    ICopyright public immutable copyright;

    uint256 totalSupply;

    // mapping from metadataId to Meta
    mapping(uint256 => Meta) internal _metaOf;

    // mapping from metadataHash to metadataId
    mapping(bytes32 => uint256) internal _hashToId;

    // mapping from metadataId to metadataHash
    mapping(uint256 => bytes32) internal _idToHash;

    constructor(ICopyright copyright_) {
        copyright = copyright_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC165, IERC165)
        returns (bool)
    {
        return interfaceId
            == type(IMetadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function supportsMetadata(IMetadata metadata)
        public
        view
        returns (bool ok)
    {
        ok = address(metadata) == address(this);
    }

    function generateSVG(uint256 metadataId)
        external
        view
        returns (string memory svg)
    {
        Meta storage meta = _metaOf[metadataId];
        RasterEngine.Frame memory frame = _getFrame(meta);
        RasterRenderer.SVGParams memory params = RasterRenderer.SVGParams({
            width: frame.width,
            height: frame.height,
            colors: meta.palette.getColors(),
            data: frame.data
        });
        svg = RasterRenderer.generateSVG(params);
    }

    function generateRawData(uint256 metadataId)
        external
        view
        returns (bytes memory raw)
    {
        raw = _getRawData(_metaOf[metadataId]);
    }

    function exists(uint256 metadataId) public view returns (bool ok) {
        ok = _idToHash[metadataId] != bytes32(0);
    }

    function width(uint256 metadataId) public view returns (uint256 w) {
        w = _metaOf[metadataId].width;
    }

    function height(uint256 metadataId) public view returns (uint256 h) {
        h = _metaOf[metadataId].height;
    }

    function getColors(uint256 metadataId)
        public
        view
        returns (bytes4[] memory colors)
    {
        colors = _metaOf[metadataId].palette.getColors();
    }

    function getIngredients(uint256 metadataId)
        external
        view
        returns (uint256[] memory tokenIds, uint256[] memory amounts)
    {
        tokenIds = _metaOf[metadataId].ingredients;
        mapping(uint256 => uint256) storage amountOf =
            _metaOf[metadataId].ingredientAmountOf;
        amounts = new uint256[](tokenIds.length);
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                amounts[i] = amountOf[tokenIds[i]];
            }
        }
    }

    /**
     * @dev data is encoded by (uint256, uint256, Layer[], bytes4[], bytes)
     */
    function verify(bytes calldata data)
        external
        returns (uint256 metadataId)
    {
        (
            uint256 w,
            uint256 h,
            Layer[] memory layers,
            bytes4[] memory colors,
            bytes memory drawing
        ) = _parseCreationData(data);

        Meta storage meta = _metaOf[0];
        meta.width = w;
        meta.height = h;
        _processLayers(meta, layers);
        _processColors(meta, colors);
        _processDrawing(meta, drawing);

        bytes memory raw = _getRawData(meta);
        bytes32 metadataHash = keccak256(raw);
        metadataId = _hashToId[metadataHash];

        delete _metaOf[0];
    }

    /**
     * @dev data is encoded by (uint256, uint256, Layer[], bytes4[], bytes)
     */
    function create(bytes calldata data)
        external
        returns (uint256 metadataId)
    {
        (
            uint256 w,
            uint256 h,
            Layer[] memory layers,
            bytes4[] memory colors,
            bytes memory drawing
        ) = _parseCreationData(data);

        metadataId = ++totalSupply;

        Meta storage meta = _metaOf[metadataId];
        meta.width = w;
        meta.height = h;
        _processLayers(meta, layers);
        _processColors(meta, colors);
        _processDrawing(meta, drawing);

        bytes memory raw = _getRawData(meta);
        bytes32 metadataHash = keccak256(raw);

        if (_hashToId[metadataHash] != uint256(0)) {
            revert AlreadyCreated(_hashToId[metadataHash]);
        }
        _hashToId[metadataHash] = metadataId;
        _idToHash[metadataId] = metadataHash;

        emit Created(metadataId);
    }

    function _parseCreationData(bytes calldata data)
        internal
        pure
        returns (
            uint256 w,
            uint256 h,
            Layer[] memory layers,
            bytes4[] memory colors,
            bytes memory drawing
        )
    {
        (w, h, layers, colors, drawing) =
            abi.decode(data, (uint256, uint256, Layer[], bytes4[], bytes));
    }

    function _processLayers(Meta storage meta, Layer[] memory layers)
        internal
    {
        unchecked {
            for (uint256 i = 0; i < layers.length; i++) {
                Layer memory layer = layers[i];

                // validate layer metadata
                (, uint256 metadataId) =
                    _validateLayer(layer, meta.width, meta.height);

                // save palette
                bytes4[] memory colors = getColors(metadataId);
                for (uint256 j = 0; j < colors.length; j++) {
                    meta.palette.addColor(colors[i]);
                }

                // save ingredients
                uint256 tokenId = layer.tokenId;
                if (meta.ingredientAmountOf[tokenId] == uint256(0)) {
                    meta.ingredients.push(tokenId);
                }
                meta.ingredientAmountOf[tokenId]++;

                // save layer
                meta.layers.push(layer);
            }
        }
    }

    function _processColors(Meta storage meta, bytes4[] memory colors)
        internal
    {
        unchecked {
            for (uint8 i = 0; i < colors.length; i++) {
                meta.palette.addColor(colors[i]);
            }
        }
    }

    function _processDrawing(Meta storage meta, bytes memory drawing)
        internal
    {
        if (drawing.length != meta.width * meta.height) {
            revert InvalidDrawing(drawing);
        }

        meta.drawingLayer = drawing;
    }

    function _validateLayer(
        Layer memory layer,
        uint256 baseWidth,
        uint256 baseHeight
    )
        internal
        view
        returns (IMetadata metadata, uint256 metadataId)
    {
        (metadata, metadataId) = copyright.metadataOf(layer.tokenId);

        if (!supportsMetadata(metadata)) {
            revert UnsupportedMetadata(metadata);
        }

        if (!exists(metadataId)) {
            revert LayerNotExisted(layer);
        }

        uint256 w;
        uint256 h;
        if (layer.rotate == Rotate.D0 || layer.rotate == Rotate.D180) {
            w = width(metadataId);
            h = height(metadataId);
        } else {
            w = height(metadataId);
            h = width(metadataId);
        }

        if (
            w + layer.translateX > baseWidth || h + layer.translateY > baseHeight
        ) {
            revert LayerOutOfBoundary(layer);
        }
    }

    function _getRawData(Meta storage meta)
        internal
        view
        returns (bytes memory raw)
    {
        bytes memory colorRaw = meta.palette.toBytes();
        RasterEngine.Frame memory frame = _getFrame(meta);
        bytes memory contentRaw = frame.toBytes();
        raw = abi.encodePacked(colorRaw, contentRaw);
    }

    function _getFrame(Meta storage meta)
        internal
        view
        returns (RasterEngine.Frame memory frame)
    {
        uint256 baseWidth = meta.width;
        uint256 baseHeight = meta.height;
        frame = RasterEngine.Frame({
            width: baseWidth,
            height: baseHeight,
            data: new bytes(baseWidth * baseHeight)
        });

        Layer[] memory layers = meta.layers;
        for (uint256 i = 0; i < layers.length; i++) {
            Layer memory layer = layers[i];
            Meta storage layerMeta = _getLayerMeta(layer.tokenId);
            RasterEngine.Frame memory layerFrame = _getFrame(layerMeta);
            layerFrame.normalizeColors(layerMeta.palette, meta.palette);
            layerFrame.transformFrame(
                layer.rotate,
                layer.flip,
                layer.translateX,
                layer.translateY,
                baseWidth,
                baseHeight
            );
            frame.addFrame(layerFrame);
        }

        RasterEngine.Frame memory drawingFrame = RasterEngine.Frame({
            width: baseWidth,
            height: baseHeight,
            data: meta.drawingLayer
        });
        frame.addFrame(drawingFrame);
    }

    function _getLayerMeta(uint256 tokenId)
        internal
        view
        returns (Meta storage meta)
    {
        (, uint256 metadataId) = copyright.metadataOf(tokenId);
        meta = _metaOf[metadataId];
    }
}
