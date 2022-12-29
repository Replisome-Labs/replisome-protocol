// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Layer, TransformParam, TransformType} from "../interfaces/Structs.sol";
import {ICopyright} from "../interfaces/ICopyright.sol";
import {IMetadata} from "../interfaces/IMetadata.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {ERC165} from "../libraries/ERC165.sol";
import {SafeCast} from "../libraries/SafeCast.sol";
import {BytesLib} from "../libraries/BytesLib.sol";
import {BoardLib} from "../utils/BoardLib.sol";
import {RasterRenderer} from "../utils/RasterRenderer.sol";

error UnsupportedMetadata(IMetadata metadata);

error AlreadyCreated(uint256 metadataId);

error NotCreated(uint256 metadataId);

error OutOfBoundary();

struct LayerLayout {
    uint256 x1;
    uint256 y1;
    uint256 x2;
    uint256 y2;
}

struct LayerCell {
    uint256 x;
    uint256 y;
}

contract RasterMetadata is IMetadata, ERC165 {
    using BytesLib for bytes;
    using BoardLib for BoardLib.Board;

    ICopyright public immutable copyright;
    uint256 public width;
    uint256 public height;

    uint256 totalSupply;

    // EMPTY_BOARD should be immutable but bytes type have not been supported for now.
    bytes public EMPTY_BOARD;

    // mapping from metadataId to tree
    mapping(uint256 => BoardLib.Board) internal _contentOf;

    // mapping from metadataId to ingredients
    mapping(uint256 => uint256[]) internal _ingredientsOf;

    // mapping from metadataid to ingredientId to amount
    mapping(uint256 => mapping(uint256 => uint256))
        internal _ingredientAmountOf;

    // mapping from metadataHash to metadataId
    mapping(bytes32 => uint256) internal _hashToId;

    // mapping from metadataId to metadataHash
    mapping(uint256 => bytes32) internal _idToHash;

    constructor(
        ICopyright copyright_,
        uint256 width_,
        uint256 height_
    ) {
        copyright = copyright_;
        width = width_;
        height = height_;
        EMPTY_BOARD = new bytes(width_ * height + 1);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IMetadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function generateSVG(uint256 metadataId)
        external
        view
        returns (string memory svg)
    {
        BoardLib.Board storage board = _contentOf[metadataId];
        RasterRenderer.SVGParams memory params = RasterRenderer.SVGParams({
            width: width,
            height: height,
            colors: board.getColors(),
            data: board.data
        });
        svg = RasterRenderer.generateSVG(params);
    }

    function readRawData(uint256 metadataId)
        external
        view
        returns (bytes memory raw)
    {
        BoardLib.Board storage board = _contentOf[metadataId];
        raw = board.toBytes();
    }

    function supportsMetadata(IMetadata metadata)
        public
        view
        returns (bool ok)
    {
        ok = address(metadata) == address(this);
    }

    function exists(uint256 metadataId) public view returns (bool ok) {
        ok = !_contentOf[metadataId].isEmpty();
    }

    function getIngredients(uint256 metadataId)
        external
        view
        returns (uint256[] memory tokenIds, uint256[] memory amounts)
    {
        tokenIds = _ingredientsOf[metadataId];
        amounts = new uint256[](tokenIds.length);
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                amounts[i] = _ingredientAmountOf[metadataId][tokenIds[i]];
            }
        }
    }

    function verify(Layer[] calldata layers, bytes calldata drawings)
        external
        returns (uint256 metadataId)
    {
        BoardLib.Board storage board = _contentOf[0];
        _buildBoard(board, layers, drawings);
        bytes32 metadataHash = _calculateHash(board);
        metadataId = _hashToId[metadataHash];
        _clearBoard(board);
    }

    function create(Layer[] calldata layers, bytes calldata drawings)
        external
        returns (uint256 metadataId)
    {
        metadataId = ++totalSupply;

        _saveLayersComposition(metadataId, layers);

        BoardLib.Board storage board = _contentOf[metadataId];
        _buildBoard(board, layers, drawings);

        bytes32 metadataHash = _calculateHash(board);
        if (_hashToId[metadataHash] != uint256(0)) {
            revert AlreadyCreated(_hashToId[metadataHash]);
        }
        _hashToId[metadataHash] = metadataId;
        _idToHash[metadataId] = metadataHash;

        emit Created(metadataId);
    }

    function _buildBoard(
        BoardLib.Board storage board,
        Layer[] memory layers,
        bytes calldata drawings
    ) internal {
        if (layers.length == 0) {
            board.fromBytes(drawings);
            return;
        }

        _addBaseLayer(board);

        for (uint256 layerIndex = 0; layerIndex < layers.length; layerIndex++) {
            Layer memory layer = layers[layerIndex];
            (IMetadata metadata, uint256 metadataId) = copyright.metadataOf(
                layer.tokenId
            );

            if (!supportsMetadata(metadata)) {
                revert UnsupportedMetadata(metadata);
            }

            if (!metadata.exists(metadataId)) {
                revert NotCreated(metadataId);
            }

            (
                LayerLayout memory layerLayout,
                bytes memory layerRaw
            ) = _parseLayerMetadata(metadata, metadataId);

            _addLayer(board, layerRaw, layerLayout, layer.transforms);
        }

        _addLayer(board, drawings);
    }

    function _clearBoard(BoardLib.Board storage board) internal {
        board.clear();
    }

    function _saveLayersComposition(uint256 metadataId, Layer[] memory layers)
        internal
    {
        for (uint256 i = 0; i < layers.length; i++) {
            uint256 tokenId = layers[i].tokenId;
            if (_ingredientAmountOf[metadataId][tokenId] == uint256(0)) {
                _ingredientsOf[metadataId].push(tokenId);
            }
            _ingredientAmountOf[metadataId][tokenId]++;
        }
    }

    function _parseLayerMetadata(IMetadata metadata, uint256 metadataId)
        internal
        view
        returns (LayerLayout memory layerLayout, bytes memory layerRaw)
    {
        if (address(metadata) == address(this)) {
            layerLayout = LayerLayout({
                x1: 0,
                y1: 0,
                x2: metadata.width() - 1,
                y2: metadata.height() - 1
            });

            BoardLib.Board storage board = _contentOf[metadataId];
            layerRaw = board.toBytes();
        }
    }

    function _calculateHash(BoardLib.Board storage board)
        internal
        view
        returns (bytes32 metadataHash)
    {
        bytes memory raw = board.toBytes();
        metadataHash = keccak256(raw);
    }

    function _addBaseLayer(BoardLib.Board storage board) internal {
        board.fromBytes(EMPTY_BOARD);
    }

    function _addLayer(BoardLib.Board storage board, bytes calldata raw)
        internal
    {
        uint8 rawColorCount = uint8(raw[0]);
        bytes4[] memory rawColors = new bytes4[](rawColorCount);
        unchecked {
            for (uint8 i = 0; i < rawColorCount; i++) {
                rawColors[i] = bytes4(raw[i * 4 + 1:i * 4 + 5]);
            }
        }

        bytes memory rawData = raw[rawColorCount * 4 + 1:];
        unchecked {
            for (uint256 j = 0; j < rawData.length; j++) {
                uint8 rawColorIndex = uint8(rawData[j]);
                if (rawColorIndex == uint8(0)) continue;
                bytes4 color = rawColors[rawColorIndex - 1];
                board.fillColor(j, color);
            }
        }
    }

    function _addLayer(
        BoardLib.Board storage board,
        bytes memory raw,
        LayerLayout memory layout,
        TransformParam[] memory transforms
    ) internal {
        uint8 rawColorCount = uint8(raw[0]);
        bytes4[] memory rawColors = new bytes4[](rawColorCount);
        unchecked {
            for (uint8 i = 0; i < rawColorCount; i++) {
                rawColors[i] = bytes4(raw.slice(i * 4 + 1, 4));
            }
        }

        uint256 rawDataStart = rawColorCount * 4 + 1;
        bytes memory rawData = raw.slice(
            rawDataStart,
            raw.length - rawDataStart
        );
        unchecked {
            for (uint256 j = 0; j < rawData.length; j++) {
                uint8 rawColorIndex = uint8(rawData[j]);
                if (rawColorIndex == uint8(0)) continue;
                bytes4 color = rawColors[rawColorIndex - 1];
                uint256 position = _transformCell(j, layout, transforms);
                board.fillColor(position, color);
            }
        }
    }

    function _transformCell(
        uint256 position,
        LayerLayout memory layout,
        TransformParam[] memory transforms
    ) internal view returns (uint256 newPosition) {
        LayerCell memory cell;
        cell.y = position / width;
        cell.x = position - (width * cell.y);

        LayerLayout memory localLayout;
        localLayout.x1 = layout.x1;
        localLayout.y1 = layout.y1;
        localLayout.x2 = layout.x2;
        localLayout.y2 = layout.y2;

        for (uint256 i = 0; i < transforms.length; i++) {
            TransformType transformType = transforms[i].transformType;
            uint256 value = transforms[i].value;
            if (transformType == TransformType.TranslateX) {
                _translateXCell(cell, localLayout, value);
            } else if (transformType == TransformType.TranslateY) {
                _translateYCell(cell, localLayout, value);
            } else if (transformType == TransformType.Rotate) {
                _rotateCell(cell, localLayout, value);
            } else if (transformType == TransformType.Flip) {
                _flipCell(cell, localLayout, value);
            }
        }

        newPosition = cell.y * width + cell.x;
    }

    function _translateXCell(
        LayerCell memory cel,
        LayerLayout memory layout,
        uint256 value
    ) internal view {
        cel.x += value;
        layout.x1 += value;
        layout.x2 += value;
        if (cel.x > width) {
            revert OutOfBoundary();
        }
    }

    function _translateYCell(
        LayerCell memory cell,
        LayerLayout memory layout,
        uint256 value
    ) internal view {
        cell.y += value;
        layout.y1 += value;
        layout.y2 += value;
        if (cell.y > height) {
            revert OutOfBoundary();
        }
    }

    /**
        @dev Rotate a cell given on layout
        Rotate clockwise 90 degree if value equals to 1.
        Rotate clockwise 180 degree if value equals to 2.
        Rotate clockwise 270 degree if value equals to 2.
     */
    function _rotateCell(
        LayerCell memory cell,
        LayerLayout memory layout,
        uint256 value
    ) internal pure {
        uint256 w = layout.x2 - layout.x1 + 1;
        uint256 h = layout.y2 - layout.y1 + 1;
        layout.x2 = layout.x1 + h - 1;
        layout.y2 = layout.y1 + w - 1;
        if (value == 1) {
            cell.x = layout.x1 + layout.y2 - cell.y + 1;
            cell.y = layout.y1 - layout.x1 + cell.x;
        } else if (value == 2) {
            cell.x = layout.x1 + layout.x2 - cell.x + 1;
            cell.y = layout.y1 + layout.y2 - cell.y + 1;
        } else if (value == 3) {
            cell.x = layout.x1 - layout.y1 + cell.y;
            cell.y = layout.x2 + layout.y1 - cell.x + 1;
        }
    }

    /**
        @dev Flip a cell given on layout
        Flip horizontally if value equals to 1.
        Flip vertically if value equals to 2.
     */
    function _flipCell(
        LayerCell memory cell,
        LayerLayout memory layout,
        uint256 value
    ) internal pure {
        if (value == 1) {
            cell.x = layout.x1 + layout.x2 - cell.x;
        } else if (value == 2) {
            cell.y = layout.y1 + layout.y2 - cell.y;
        }
    }
}
