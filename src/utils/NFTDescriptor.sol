// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {INFTRenderer} from "../interfaces/INFTRenderer.sol";
import {Base64} from "../libraries/Base64.sol";

library NFTDescriptor {
    struct TokenURIParams {
        string name;
        string description;
        INFTRenderer renderer;
        uint256 id;
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(TokenURIParams memory params)
        public
        view
        returns (string memory)
    {
        string memory image = generateSVGImage(params.renderer, params.id);

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', params.name, '", "description":"', params.description, '", "image": "', 'data:image/svg+xml;base64,', image, '"}')
                    )
                )
            )
        );
    }

    /**
     * @notice Generate an SVG image for use in the NFT URI.
     */
    function generateSVGImage(INFTRenderer renderer, uint256 id)
        public
        view
        returns (string memory svg)
    {
        if (address(renderer) == address(0)) {
            svg = "";
        } else {
            svg = Base64.encode(bytes(renderer.generateSVG(id)));
        }
    }
}
