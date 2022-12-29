// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Base64} from "../libraries/Base64.sol";
import {Strings} from "../libraries/Strings.sol";
import {Grid} from "./Grid.sol";

library RasterRendererV2 {
    using Strings for uint256;
    using Strings for bytes3;

    struct SVGParams {
        uint256 width;
        uint256 height;
        Grid.Point[] points;
        bytes32[] values;
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

        for (uint256 i = 0; i < params.points.length; i++) {
            string memory rect = _getRect(params.points[i], params.values[i]);
            rects = string(abi.encodePacked(rects, rect));
        }

        partialSVG = string(abi.encodePacked("<g>", rects, "</g>"));
    }

    function _getRect(Grid.Point memory point, bytes32 value)
        private
        pure
        returns (string memory partialSVG)
    {
        uint256 x = uint256(point.x) * _pixelSize;
        uint256 y = uint256(point.y) * _pixelSize;
        bytes4 v = bytes4(value);
        bytes3 c = bytes3(v);
        uint256 o = (uint256(uint8(uint32(v))) * 100) /
            uint256(type(uint8).max);
        partialSVG = string(
            abi.encodePacked(
                '<rect width="',
                _pixelSize.toString(),
                '" height="',
                _pixelSize.toString(),
                '" x="',
                x.toString(),
                '" y="',
                y.toString(),
                '" fill="#',
                c.toColorString(),
                '" fill-opacity="',
                o.toString(),
                '%" />'
            )
        );
    }
}
