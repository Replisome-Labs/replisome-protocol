// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ICopyright} from "../interfaces/ICopyright.sol";
import {INFTRenderer} from "../interfaces/INFTRenderer.sol";
import {Strings} from "../libraries/Strings.sol";
import {svg} from "../libraries/SVG.sol";

contract CopyrightRenderer is INFTRenderer {
    using Strings for uint256;
    using Strings for address;

    string public constant MIMEType = "image/svg+xml";

    ICopyright public immutable copyright;

    string private constant _SVG_START_TAG =
        '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" style="background:#000">';
    string private constant _SVG_END_TAG = "</svg>";

    constructor(ICopyright copyright_) {
        copyright = copyright_;
    }

    function generateFile(uint256 tokenId)
        public
        view
        returns (string memory file)
    {
        address owner = copyright.ownerOf(tokenId);
        address creator = copyright.creatorOf(tokenId);

        file = string.concat(
            _SVG_START_TAG,
            svg.text(
                string.concat(
                    svg.prop("x", "20"),
                    svg.prop("y", "40"),
                    svg.prop("font-size", "22"),
                    svg.prop("fill", "#ccc")
                ),
                svg.cdata("Replisome.xyz Copyright")
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "20"),
                    svg.prop("y", "80"),
                    svg.prop("font-size", "32"),
                    svg.prop("fill", "#ccc")
                ),
                string.concat(svg.cdata("#"), tokenId.toString())
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "20"),
                    svg.prop("y", "230"),
                    svg.prop("font-size", "14"),
                    svg.prop("fill", "#999")
                ),
                svg.cdata("Creator")
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "20"),
                    svg.prop("y", "245"),
                    svg.prop("font-size", "12"),
                    svg.prop("fill", "#999")
                ),
                creator.toHexString()
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "20"),
                    svg.prop("y", "265"),
                    svg.prop("font-size", "14"),
                    svg.prop("fill", "#999")
                ),
                svg.cdata("Owner")
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "20"),
                    svg.prop("y", "280"),
                    svg.prop("font-size", "12"),
                    svg.prop("fill", "#999")
                ),
                owner.toHexString()
            ),
            _SVG_END_TAG
        );
    }
}
