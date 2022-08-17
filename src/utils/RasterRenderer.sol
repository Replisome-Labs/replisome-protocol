// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Base64} from "../libraries/Base64.sol";
import {Strings} from "../libraries/Strings.sol";
import {Quadtree} from "../utils/Quadtree.sol";

library RasterRenderer {
    using Strings for uint256;
    using Strings for bytes3;

    struct SVGParams {
        uint256 width;
        uint256 height;
        Quadtree.Node[] nodes;
    }

    uint256 private constant _pixelSize = 10;
    string private constant _SVG_END_TAG = "</svg>";

    function generateSVG(SVGParams memory params)
        external
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                _generateSVGStartTag(params),
                _generateSVGRects(params),
                _SVG_END_TAG
            )
        );
    }

    function _generateSVGStartTag(SVGParams memory params)
        private
        pure
        returns (string memory partialSVG)
    {
        uint256 w = params.width * _pixelSize;
        uint256 h = params.height * _pixelSize;
        partialSVG = string(
            abi.encodePacked(
                '<svg width="',
                w.toString(),
                '" height="',
                h.toString(),
                '" viewBox="0 0 ',
                w.toString(),
                " ",
                h.toString(),
                '" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" preserveAspectRatio="meet">'
            )
        );
    }

    function _generateSVGRects(SVGParams memory params)
        private
        pure
        returns (string memory partialSVG)
    {
        string memory rects;

        for (uint256 i = 0; i < params.nodes.length; i++) {
            string memory rect = _getRect(params.nodes[i]);
            rects = string(abi.encodePacked(rects, rect));
        }

        partialSVG = string(abi.encodePacked("<g>", rects, "</g>"));
    }

    function _getRect(Quadtree.Node memory node)
        private
        pure
        returns (string memory partialSVG)
    {
        uint256 l = uint256(node.l) * _pixelSize;
        uint256 x = uint256(node.x) * _pixelSize;
        uint256 y = uint256(node.y) * _pixelSize;
        bytes3 c = bytes3(node.data);
        uint256 o = uint256((uint8(node.data[3]) * 100) / type(uint8).max);
        partialSVG = string(
            abi.encodePacked(
                '<rect width="',
                l.toString(),
                '" height="',
                l.toString(),
                '" x="',
                x.toString(),
                '" y="',
                y.toString(),
                '" fill="',
                c.toHexString(),
                '" fill-opacity="',
                o.toString(),
                '%" />'
            )
        );
    }
}
