// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error NotEmptyQuadtree();

error InvalidQuadtreeBoundary();

error InvalidQuadtreeNode();

error CanNotSubdivide(uint32 nodeIndex);

library Quadtree {
    struct Node {
        uint32 x;
        uint32 y;
        uint32 l;
        uint32 tl;
        uint32 tr;
        uint32 bl;
        uint32 br;
        bytes4 data;
    }

    function fromBytes(bytes calldata raw)
        public
        pure
        returns (Node memory node)
    {
        node = Node({
            x: uint32(bytes4(raw[0:4])),
            y: uint32(bytes4(raw[4:8])),
            l: uint32(bytes4(raw[8:12])),
            tl: uint32(bytes4(raw[12:16])),
            tr: uint32(bytes4(raw[16:20])),
            bl: uint32(bytes4(raw[20:24])),
            br: uint32(bytes4(raw[24:28])),
            data: bytes4(raw[28:32])
        });
    }

    function toBytes(Node memory node) public pure returns (bytes memory raw) {
        raw = abi.encodePacked(
            node.x,
            node.y,
            node.l,
            node.tl,
            node.tr,
            node.bl,
            node.br,
            node.data
        );
    }

    function isLeaf(Node memory node) public pure returns (bool result) {
        result =
            node.tl == uint32(0) &&
            node.tr == uint32(0) &&
            node.bl == uint32(0) &&
            node.br == uint32(0);
    }

    function isAtom(Node memory node) public pure returns (bool result) {
        result = node.l == uint32(1);
    }

    function equals(Node memory nodeA, Node memory nodeB)
        public
        pure
        returns (bool result)
    {
        result = nodeA.x == nodeB.x && nodeA.y == nodeB.y && nodeA.l == nodeB.l;
    }

    function includes(Node memory nodeA, Node memory nodeB)
        public
        pure
        returns (bool result)
    {
        result =
            nodeA.x <= nodeB.x &&
            nodeB.x + nodeB.l <= nodeA.x + nodeA.l &&
            nodeA.y <= nodeB.y &&
            nodeB.y + nodeB.l <= nodeA.y + nodeA.l;
    }

    struct Tree {
        uint32 size;
        uint32 root;
        mapping(uint32 => Node) nodes;
    }

    function isEmpty(Tree storage tree) public view returns (bool result) {
        result = tree.size == uint32(0) || tree.root == uint32(0);
    }

    function init(Tree storage tree, uint32 boundary) public {
        if (!isEmpty(tree)) {
            revert NotEmptyQuadtree();
        }
        if (!isPowerOfTwo(boundary)) {
            revert InvalidQuadtreeBoundary();
        }
        tree.root = ++tree.size;
        tree.nodes[tree.root].l = boundary;
    }

    function subdivide(Tree storage tree, uint32 nodeIndex) public {
        Node memory node = tree.nodes[nodeIndex];
        if (!isLeaf(node) || isAtom(node)) {
            revert CanNotSubdivide(nodeIndex);
        }

        uint32 size = tree.size;
        uint32 half = node.l / 2;

        tree.nodes[nodeIndex] = Node({
            x: node.x,
            y: node.y,
            l: node.l,
            tl: size + 1,
            tr: size + 2,
            bl: size + 3,
            br: size + 4,
            data: bytes4(0)
        });

        tree.nodes[size + 1] = Node({
            x: node.x,
            y: node.y,
            l: half,
            tl: uint32(0),
            tr: uint32(0),
            bl: uint32(0),
            br: uint32(0),
            data: node.data
        });
        tree.nodes[size + 2] = Node({
            x: node.x + half,
            y: node.y,
            l: half,
            tl: uint32(0),
            tr: uint32(0),
            bl: uint32(0),
            br: uint32(0),
            data: node.data
        });
        tree.nodes[size + 3] = Node({
            x: node.x,
            y: node.y + half,
            l: half,
            tl: uint32(0),
            tr: uint32(0),
            bl: uint32(0),
            br: uint32(0),
            data: node.data
        });
        tree.nodes[size + 4] = Node({
            x: node.x + half,
            y: node.y + half,
            l: half,
            tl: uint32(0),
            tr: uint32(0),
            bl: uint32(0),
            br: uint32(0),
            data: node.data
        });

        tree.size += 4;
    }

    function insert(Tree storage tree, Node memory node) public {
        if (includes(node, tree.nodes[tree.root])) {
            revert InvalidQuadtreeNode();
        }

        uint32 i;
        do {
            i++;
            Node memory current = tree.nodes[i];
            if (equals(current, node)) {
                tree.nodes[i].data = node.data;
                break;
            }
            if (
                isLeaf(current) && !isAtom(current) && includes(current, node)
            ) {
                subdivide(tree, i);
            }
        } while (i <= tree.size);
    }

    function clear(Tree storage tree) public {
        for (uint32 i = 0; i <= tree.size; i++) {
            delete tree.nodes[i];
        }
        tree.size = 0;
        tree.root = 0;
    }

    function getLeaves(Tree storage tree) public view returns (Node[] memory nodes) {
        uint256 amount = 0;

        unchecked {
            for (uint32 i = 1; i <= tree.size; i++) {
                if (isLeaf(tree.nodes[i])) {
                    amount++;
                }
            }
        }

        nodes = new Node[](amount);
        uint256 nodeIndex = 0;
        unchecked {
            for (uint32 i = 1; i <= tree.size; i++) {
                Node memory node = tree.nodes[i];
                if (isLeaf(node)) {
                    nodes[nodeIndex] = node;
                    nodeIndex++;
                }
            }
        }
    }

    function isPowerOfTwo(uint32 x) public pure returns (bool result) {
        assembly {
            switch x
            case 1 { result := true }
            case 2 { result := true }
            case 4 { result := true }
            case 8 { result := true }
            case 16 { result := true }
            case 32 { result := true }
            case 64 { result := true }
            case 128 { result := true }
            case 256 { result := true }
            case 512 { result := true }
            case 1024 { result := true }
            case 2048 { result := true }
            case 4096 { result := true }
            case 8192 { result := true }
            case 16384 { result := true }
            case 32768 { result := true }
            case 65536 { result := true }
            case 131072 { result := true }
            case 262144 { result := true }
            case 524288 { result := true }
            case 1048576 { result := true }
            case 2097152 { result := true }
            case 4194304 { result := true }
            case 8388608 { result := true }
            case 16777216 { result := true }
            case 33554432 { result := true }
            case 67108864 { result := true }
            case 134217728 { result := true }
            case 268435456 { result := true }
            case 536870912 { result := true }
            case 1073741824 { result := true }
            case 2147483648 { result := true }
        }
    }
}
