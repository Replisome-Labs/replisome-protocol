// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Layer, LayerLayout, TransformParam, TransformType} from "./interfaces/Structs.sol";
import {ICopyright} from "./interfaces/ICopyright.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {ERC165} from "./libraries/ERC165.sol";
import {SafeCast} from "./libraries/SafeCast.sol";
import {Quadtree} from "./utils/Quadtree.sol";
import {RasterRenderer} from "./utils/RasterRenderer.sol";

error UnsupportedMetadata(IMetadata metadata);

error AlreadyCreated(uint256 metadataId);

error NotCreated(uint256 metadataId);

error OutOfBoundary();

error MisOrderedTransforms();

contract RasterMetadata is IMetadata, ERC165 {
    using SafeCast for uint256;
    using Quadtree for Quadtree.Tree;
    using Quadtree for Quadtree.Node;

    ICopyright public immutable copyright;
    uint256 public immutable width;
    uint256 public immutable height;
    uint32 public immutable boundary;

    uint256 totalSupply;

    // mapping from metadataId to tree
    mapping(uint256 => Quadtree.Tree) internal _treeOf;

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
        uint256 height_,
        uint32 boundary_
    ) {
        copyright = copyright_;
        width = width_;
        height = height_;
        boundary = boundary_;
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
        Quadtree.Tree storage tree = _treeOf[metadataId];
        Quadtree.Node[] memory nodes = tree.getLeaves();
        RasterRenderer.SVGParams memory params = RasterRenderer.SVGParams({
            width: width,
            height: height,
            nodes: nodes
        });
        svg = RasterRenderer.generateSVG(params);
    }

    function readRawData(uint256 metadataId)
        external
        view
        returns (bytes memory raw)
    {
        Quadtree.Tree storage tree = _treeOf[metadataId];
        Quadtree.Node[] memory nodes = tree.getLeaves();
        unchecked {
            for (uint256 i = 0; i < nodes.length; i++) {
                raw = abi.encodePacked(raw, nodes[i].toBytes());
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
        ok = !_treeOf[metadataId].isEmpty();
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
        Quadtree.Tree storage tree = _treeOf[0];
        _buildTree(tree, layers, drawings);
        bytes32 metadataHash = _calculateHash(tree);
        metadataId = _hashToId[metadataHash];
        _clearTree(tree);
    }

    function create(Layer[] calldata layers, bytes calldata drawings)
        external
        returns (uint256 metadataId)
    {
        metadataId = ++totalSupply;

        _parseIngredients(metadataId, layers);

        Quadtree.Tree storage tree = _treeOf[metadataId];
        _buildTree(tree, layers, drawings);

        bytes32 metadataHash = _calculateHash(tree);
        if (_hashToId[metadataHash] != uint256(0)) {
            revert AlreadyCreated(_hashToId[metadataHash]);
        }
        _hashToId[metadataHash] = metadataId;
        _idToHash[metadataId] = metadataHash;

        emit Created(metadataId);
    }

    function _parseIngredients(uint256 metadataId, Layer[] memory layers)
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

    function _buildTree(
        Quadtree.Tree storage tree,
        Layer[] calldata layers,
        bytes calldata drawings
    ) internal {
        if (tree.isEmpty()) {
            tree.init(boundary);
        }

        for (uint256 i = 0; i < layers.length; i++) {
            Layer memory layer = layers[i];
            (IMetadata metadata, uint256 metadataId) = copyright.metadataOf(
                layer.tokenId
            );

            if (!supportsMetadata(metadata)) {
                revert UnsupportedMetadata(metadata);
            }

            if (!exists(metadataId)) {
                revert NotCreated(metadataId);
            }

            (
                LayerLayout memory layout,
                Quadtree.Node[] memory nodes
            ) = _parseLayerMetadata(metadata, metadataId);

            for (uint256 j = 0; j < nodes.length; j++) {
                tree.insert(_transformNode(layout, nodes[i], layer.transforms));
            }
        }

        for (uint256 k = 0; k < drawings.length; k += 32) {
            Quadtree.Node memory node = Quadtree.fromBytes(drawings[k:k + 32]);
            tree.insert(node);
        }
    }

    function _clearTree(Quadtree.Tree storage tree) internal {
        tree.clear();
    }

    function _calculateHash(Quadtree.Tree storage tree)
        internal
        view
        returns (bytes32 metadataHash)
    {
        bytes memory raw;
        unchecked {
            for (uint32 i = 1; i <= tree.size; i++) {
                Quadtree.Node memory node = tree.nodes[i];
                if (!node.isLeaf()) continue;
                raw = abi.encodePacked(raw, node.toBytes());
            }
        }
        metadataHash = keccak256(raw);
    }

    function _parseLayerMetadata(IMetadata metadata, uint256 metadataId)
        internal
        view
        returns (LayerLayout memory layout, Quadtree.Node[] memory nodes)
    {
        if (address(metadata) == address(this)) {
            layout.width = metadata.width();
            layout.height = metadata.height();

            Quadtree.Tree storage tree = _treeOf[metadataId];
            nodes = tree.getLeaves();
        }
    }

    function _transformNode(
        LayerLayout memory layout,
        Quadtree.Node memory node,
        TransformParam[] memory transforms
    ) internal view returns (Quadtree.Node memory newNode) {
        newNode = node;
        bool isTranslated = false;
        for (uint256 i = 0; i < transforms.length; i++) {
            TransformType transformType = transforms[i].transformType;
            uint256 value = transforms[i].value;
            if (transformType == TransformType.TranslateX) {
                newNode = _translateXNode(newNode, value);
                isTranslated = true;
            } else if (transformType == TransformType.TranslateY) {
                newNode = _translateYNode(newNode, value);
                isTranslated = true;
            } else if (transformType == TransformType.Rotate) {
                if (isTranslated) revert MisOrderedTransforms();
                (layout, newNode) = _rotateNode(layout, newNode, value);
            } else if (transformType == TransformType.Flip) {
                if (isTranslated) revert MisOrderedTransforms();
                (layout, newNode) = _flipNode(layout, newNode, value);
            }
        }
    }

    function _translateXNode(Quadtree.Node memory node, uint256 value)
        internal
        view
        returns (Quadtree.Node memory newNode)
    {
        newNode = node;
        newNode.x += value.toUint32();
        if (newNode.x + newNode.l > width) {
            revert OutOfBoundary();
        }
    }

    function _translateYNode(Quadtree.Node memory node, uint256 value)
        internal
        view
        returns (Quadtree.Node memory newNode)
    {
        newNode = node;
        newNode.y += value.toUint32();
        if (newNode.y + newNode.l > height) {
            revert OutOfBoundary();
        }
    }

    function _rotateNode(
        LayerLayout memory layout,
        Quadtree.Node memory node,
        uint256 value
    )
        internal
        pure
        returns (LayerLayout memory newLayout, Quadtree.Node memory newNode)
    {
        newLayout.width = layout.height;
        newLayout.height = layout.width;
        newNode = node;
        if (value == 1) {
            newNode.x = layout.height.toUint32() - node.y;
            newNode.y = node.x;
        } else if (value == 2) {
            newNode.x = layout.width.toUint32() - node.x;
            newNode.y = layout.height.toUint32() - node.y;
        } else if (value == 3) {
            newNode.x = node.y;
            newNode.y = layout.width.toUint32() - node.x;
        }
    }

    function _flipNode(
        LayerLayout memory layout,
        Quadtree.Node memory node,
        uint256 value
    )
        internal
        pure
        returns (LayerLayout memory newLayout, Quadtree.Node memory newNode)
    {
        newLayout = layout;
        newNode = node;
        if (value == 1) {
            newNode.x = layout.width.toUint32() - node.x;
        } else if (value == 2) {
            newNode.y = layout.height.toUint32() - node.y;
        }
    }
}
