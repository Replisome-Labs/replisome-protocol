// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Property} from "../interfaces/Structs.sol";
import {ICopyright} from "../interfaces/ICopyright.sol";
import {ICopyrightRenderer} from "../interfaces/ICopyrightRenderer.sol";
import {IMetadata} from "../interfaces/IMetadata.sol";
import {Base64} from "../libraries/Base64.sol";
import {Strings} from "../libraries/Strings.sol";

contract CopyrightRenderer is ICopyrightRenderer {
    using Strings for uint256;
    using Strings for address;

    ICopyright public immutable copyright;

    string private constant _SVG_START_TAG =
        '<svg width="320" height="320" viewBox="0 0 320 320" fill="none" xmlns="http://www.w3.org/2000/svg">';
    string private constant _SVG_END_TAG = "</svg>";

    constructor(ICopyright copyright_) {
        copyright = copyright_;
    }

    function generateSVG(uint256 tokenId)
        public
        view
        returns (string memory svg)
    {
        address owner = copyright.ownerOf(tokenId);
        (IMetadata metadata, uint256 metadataId) = copyright.metadataOf(
            tokenId
        );
        address creator = copyright.creatorOf(tokenId);
        svg = string(
            abi.encodePacked(
                _SVG_START_TAG,
                _generateSVGDefs(),
                '<g clip-path="url(#c1)">',
                _generateSVGStatic(),
                _generateSVGPreviewImage(metadata, metadataId),
                _generateSVGTexts(tokenId, owner, creator, address(metadata)),
                "</g>",
                _SVG_END_TAG
            )
        );
    }

    function _generateSVGDefs()
        private
        pure
        returns (string memory partialSVG)
    {
        partialSVG = string(
            abi.encodePacked(
                "<defs>",
                '<linearGradient id="g1" x1="320" y1="0" x2="0" y2="320" gradientUnits="userSpaceOnUse">',
                '<stop stop-color="#F08345" stop-opacity="0.6"/>',
                '<stop offset="1" stop-color="#FCD268" stop-opacity="0.6"/>',
                "</linearGradient>",
                '<radialGradient id="g2" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(39.5 43.5) rotate(44.5885) scale(393.869 242.251)">',
                '<stop stop-color="#339CD7"/>',
                '<stop offset="1" stop-color="white" stop-opacity="0"/>',
                "</radialGradient>",
                '<clipPath id="c1">'
                '<rect width="320" height="320" fill="white"/>',
                "</clipPath>",
                "</defs>"
            )
        );
    }

    function _generateSVGStatic()
        private
        pure
        returns (string memory partialSVG)
    {
        partialSVG = string(
            abi.encodePacked(
                '<rect width="320" height="320" fill="url(#g1)"/>',
                '<rect width="320" height="320" fill="url(#g2)" fill-opacity="0.4"/>'
                '<path fill-ruleset="evenodd" clip-ruleset="evenodd" d="M43.1818 20H38.5454V24.6364H43.1818V20ZM38.5455 24.6364H33.9091V29.2727H29.2727V33.9091H33.9091H33.9091H38.5455V29.2727H43.1818V24.6364H38.5455ZM29.2727 38.5455V33.9091H33.9091V38.5455H29.2727ZM24.6364 38.5455H29.2727V43.1818H24.6364V38.5455ZM29.2727 52.4545V47.8182V43.1818H24.6364L24.6364 43.6454H20V48.2818H24.6364L24.6364 52.4545H29.2727ZM29.2727 47.8182V52.4545V57.0909V61.7273H33.9091V66.3636L38.5454 66.3636V71H43.1818V66.3636V61.7273L38.5455 61.7273V57.0909L33.9091 57.0909V52.4545V47.8182H29.2727ZM33.9091 38.5455V43.1818H29.2727V38.5455H33.9091ZM43.1818 24.6364H47.8182V29.2727L52.4545 29.2727V33.9091H47.8182H43.1818V29.2727V24.6364ZM52.4545 38.5455V33.9091H47.8182V38.5455H52.4545ZM47.8182 43.1818V38.5455H52.4545H57.0909V43.1818H52.4545H47.8182ZM57.0909 43.1818V47.8182V52.4545H52.4545L52.4545 57.0909V61.7273H47.8182L47.8182 66.3636H43.1818V61.7273V57.0909H47.8182V52.4545V47.8182L52.4545 47.8182V43.1818H57.0909ZM57.0909 43.1818H61.7273V47.8182H57.0909V43.1818ZM38.5454 43.1818H43.1818V47.8182H38.5454V43.1818Z" fill="#FCD268"/>',
                '<line x1="0" y1="155" x2="320" y2="155" stroke="black" stroke-opacity="0.3"/>',
                '<line x1="0" y1="210" x2="320" y2="210" stroke="black" stroke-opacity="0.3"/>',
                '<line x1="0" y1="265" x2="320" y2="265" stroke="black" stroke-opacity="0.3"/>',
                '<rect x="191" y="21" width="108" height="108" stroke="black" stroke-opacity="0.3" stroke-width="8"/>',
                '<rect x="195" y="25" width="100" height="100" fill="white"/>',
                '<text x="20" y="176" fill="#23353F" font-size="12" font-family="Monaco">Owner</text>',
                '<text x="20" y="231" fill="#23353F" font-size="12" font-family="Monaco">Creator</text>',
                '<text x="20" y="286" fill="#23353F" font-size="12" font-family="Monaco">Metadata Type</text>'
            )
        );
    }

    function _generateSVGTexts(
        uint256 tokenId,
        address owner,
        address creator,
        address metadata
    ) private pure returns (string memory partialSVG) {
        partialSVG = string(
            abi.encodePacked(
                '<text x="20" y="198" fill="#23353F" font-size="12" font-family="Monaco">',
                owner.toHexString(),
                "</text>",
                '<text x="20" y="253" fill="#23353F" font-size="12" font-family="Monaco">',
                creator.toHexString(),
                "</text>",
                '<text x="20" y="308" fill="#23353F" font-size="12" font-family="Monaco">',
                metadata.toHexString(),
                "</text>",
                '<text x="20" y="135" fill="#23353F" font-size="24" font-family="Monaco"># ',
                tokenId.toString(),
                "</text>"
            )
        );
    }

    function _generateSVGPreviewImage(IMetadata metadata, uint256 metadataId)
        private
        view
        returns (string memory partialSVG)
    {
        string memory image = Base64.encode(
            bytes(metadata.generateSVG(metadataId))
        );
        partialSVG = string(
            abi.encodePacked(
                '<image x="195" y="25" width="100" height="100" href="data:image/svg+xml;base64,',
                image,
                '" />'
            )
        );
    }
}
