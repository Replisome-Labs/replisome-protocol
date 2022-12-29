// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Layer, TransformParam, TransformType} from "../interfaces/Structs.sol";
import {ICopyright} from "../interfaces/ICopyright.sol";
import {IMetadata} from "../interfaces/IMetadata.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {ERC165} from "../libraries/ERC165.sol";
import {SafeCast} from "../libraries/SafeCast.sol";
import {RasterRendererV2} from "./RasterRendererV2.sol";
import {Grid} from "./Grid.sol";

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

contract RasterMetadataV2 is IMetadata, ERC165 {
    using Grid for Grid.Board;

    ICopyright public immutable copyright;
    uint256 public width;
    uint256 public height;

    uint256 totalSupply;

    // mapping from metadataId to tree
    mapping(uint256 => Grid.Board) internal _contentOf;

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
        Grid.Board storage board = _contentOf[metadataId];
        Grid.Point[] memory points = board.points;
        bytes32[] memory values = board.getValues();
        RasterRendererV2.SVGParams memory params = RasterRendererV2.SVGParams({
            width: width,
            height: height,
            points: points,
            values: values
        });
        svg = RasterRendererV2.generateSVG(params);
    }

    function readRawData(uint256 metadataId)
        external
        view
        returns (bytes memory raw)
    {
        Grid.Board storage board = _contentOf[metadataId];
        Grid.Point[] memory points = board.points;
        unchecked {
            for (uint256 i = 0; i < points.length; i++) {
                Grid.Point memory point = points[i];
                raw = abi.encodePacked(
                    raw,
                    point.x,
                    point.y,
                    board.pointValues[point.x][point.y]
                );
            }
        }
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
        // (Grid.Point[] memory points, bytes32[] memory values) = _parseDrawings(
        //     drawings
        // );
        // Grid.Board storage board = _contentOf[0];
        // _buildBoard(board, layers, points, values);
        // bytes32 metadataHash = _calculateHash(board);
        // metadataId = _hashToId[metadataHash];
        // _clearBoard(board);
    }

    function create(Layer[] calldata layers, bytes calldata drawings)
        external
        returns (uint256 metadataId)
    {
        metadataId = ++totalSupply;

        _saveLayersComposition(metadataId, layers);

        // (Grid.Point[] memory points, bytes32[] memory values) = _parseDrawings(
        //     drawings
        // );

        Grid.Board storage board = _contentOf[metadataId];
        // _buildBoard(board, layers, points, values);
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
        Grid.Board storage board,
        Layer[] memory layers,
        bytes calldata drawings // Grid.Point[] memory points, // bytes32[] memory values
    ) internal {
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
                LayerLayout memory layout,
                Grid.Point[] memory layerPoints,
                bytes32[] memory layerPointValues
            ) = _parseLayerMetadata(metadata, metadataId);

            for (
                uint256 layerPointIndex = 0;
                layerPointIndex < layerPoints.length;
                layerPointIndex++
            ) {
                board.insert(
                    _transformPoint(
                        layerPoints[layerPointIndex],
                        layout,
                        layer.transforms
                    ),
                    layerPointValues[layerPointIndex]
                );
            }
        }

        // for (uint256 pointIndex = 0; pointIndex < points.length; pointIndex++) {
        //     board.insert(points[pointIndex], values[pointIndex]);
        // }
        for (uint256 k = 0; k < drawings.length; k += 96) {
            board.insert(
                Grid.Point({
                    x: uint256(bytes32(drawings[k:k + 32])),
                    y: uint256(bytes32(drawings[k + 32:k + 64]))
                }),
                bytes32(drawings[k + 64:k + 96])
            );
        }
    }

    function _clearBoard(Grid.Board storage board) internal {
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

    function _parseDrawings(bytes calldata drawings)
        internal
        pure
        returns (Grid.Point[] memory points, bytes32[] memory values)
    {
        points = new Grid.Point[](drawings.length / 96);
        values = new bytes32[](drawings.length / 96);
        uint256 i = 0;
        for (uint256 k = 0; k < drawings.length; k += 96) {
            points[i] = Grid.Point({
                x: uint256(bytes32(drawings[k:k + 32])),
                y: uint256(bytes32(drawings[k + 32:k + 64]))
            });
            values[i] = bytes32(drawings[k + 64:k + 96]);
            i++;
        }
    }

    function _parseLayerMetadata(IMetadata metadata, uint256 metadataId)
        internal
        view
        returns (
            LayerLayout memory layout,
            Grid.Point[] memory layerPoints,
            bytes32[] memory layerPointValues
        )
    {
        if (address(metadata) == address(this)) {
            layout = LayerLayout({
                x1: 0,
                y1: 0,
                x2: metadata.width() - 1,
                y2: metadata.height() - 1
            });

            Grid.Board storage board = _contentOf[metadataId];
            layerPoints = board.points;
            layerPointValues = board.getValues();
        }
    }

    function _calculateHash(Grid.Board storage board)
        internal
        view
        returns (bytes32 metadataHash)
    {
        bytes memory raw;
        unchecked {
            for (uint256 x = 0; x < width; x++) {
                for (uint256 y = 0; y < height; y++) {
                    bytes32 data = board.at(Grid.Point(x, y));
                    raw = abi.encodePacked(raw, bytes4(data));
                }
            }
        }
        metadataHash = keccak256(raw);
    }

    function _transformPoint(
        Grid.Point memory point,
        LayerLayout memory layout,
        TransformParam[] memory transforms
    ) internal view returns (Grid.Point memory newPoint) {
        newPoint.x = point.x;
        newPoint.y = point.y;
        LayerLayout memory copiedLayout = LayerLayout({
            x1: layout.x1,
            y1: layout.y1,
            x2: layout.x2,
            y2: layout.y2
        });

        for (uint256 i = 0; i < transforms.length; i++) {
            TransformType transformType = transforms[i].transformType;
            uint256 value = transforms[i].value;
            if (transformType == TransformType.TranslateX) {
                _translateXPoint(newPoint, copiedLayout, value);
            } else if (transformType == TransformType.TranslateY) {
                _translateYPoint(newPoint, copiedLayout, value);
            } else if (transformType == TransformType.Rotate) {
                _rotatePoint(newPoint, copiedLayout, value);
            } else if (transformType == TransformType.Flip) {
                _flipPoint(newPoint, copiedLayout, value);
            }
        }
    }

    function _translateXPoint(
        Grid.Point memory point,
        LayerLayout memory layout,
        uint256 value
    ) internal view {
        point.x += value;
        layout.x1 += value;
        layout.x2 += value;
        if (point.x > width) {
            revert OutOfBoundary();
        }
    }

    function _translateYPoint(
        Grid.Point memory point,
        LayerLayout memory layout,
        uint256 value
    ) internal view {
        point.y += value;
        layout.y1 += value;
        layout.y2 += value;
        if (point.y > height) {
            revert OutOfBoundary();
        }
    }

    /**
        @dev Rotate a point given on layout
        Rotate clockwise 90 degree if value equals to 1.
        Rotate clockwise 180 degree if value equals to 2.
        Rotate clockwise 270 degree if value equals to 2.
     */
    function _rotatePoint(
        Grid.Point memory point,
        LayerLayout memory layout,
        uint256 value
    ) internal pure {
        uint256 w = layout.x2 - layout.x1 + 1;
        uint256 h = layout.y2 - layout.y1 + 1;
        layout.x2 = layout.x1 + h - 1;
        layout.y2 = layout.y1 + w - 1;
        if (value == 1) {
            point.x = layout.x1 + layout.y2 - point.y + 1;
            point.y = layout.y1 - layout.x1 + point.x;
        } else if (value == 2) {
            point.x = layout.x1 + layout.x2 - point.x + 1;
            point.y = layout.y1 + layout.y2 - point.y + 1;
        } else if (value == 3) {
            point.x = layout.x1 - layout.y1 + point.y;
            point.y = layout.x2 + layout.y1 - point.x + 1;
        }
    }

    /**
        @dev Flip a point given on layout
        Flip horizontally if value equals to 1.
        Flip vertically if value equals to 2.
     */
    function _flipPoint(
        Grid.Point memory point,
        LayerLayout memory layout,
        uint256 value
    ) internal pure {
        if (value == 1) {
            point.x = layout.x1 + layout.x2 - point.x;
        } else if (value == 2) {
            point.y = layout.y1 + layout.y2 - point.y;
        }
    }
}
