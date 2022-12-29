// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Strings} from "../libraries/Strings.sol";

library RasterRenderer {
    using Strings for uint256;
    using Strings for bytes3;

    struct SVGParams {
        uint256 width;
        uint256 height;
        bytes4[] colors;
        bytes data;
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

        for (uint256 i = 0; i < params.data.length; i++) {
            uint256 y = i / params.width;
            uint256 x = i - (params.width * y);
            uint8 colorIndex = uint8(params.data[i]);
            if (colorIndex == uint8(0)) continue;
            bytes4 color = params.colors[colorIndex - 1];
            string memory rect = _getRect(x, y, color);
            rects = string(abi.encodePacked(rects, rect));
        }

        partialSVG = string(abi.encodePacked("<g>", rects, "</g>"));
    }

    function _getRect(
        uint256 x,
        uint256 y,
        bytes4 value
    ) private pure returns (string memory partialSVG) {
        uint256 rectX = uint256(x) * _pixelSize;
        uint256 rectY = uint256(y) * _pixelSize;
        bytes3 c = bytes3(value);
        uint256 o = (uint256(uint8(uint32(value))) * 100) /
            uint256(type(uint8).max);
        partialSVG = string(
            abi.encodePacked(
                '<rect width="',
                _pixelSize.toString(),
                '" height="',
                _pixelSize.toString(),
                '" x="',
                rectX.toString(),
                '" y="',
                rectY.toString(),
                '" fill="#',
                c.toColorString(),
                '" fill-opacity="',
                o.toString(),
                '%" />'
            )
        );
    }
}
