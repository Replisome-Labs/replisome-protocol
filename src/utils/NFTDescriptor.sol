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
        string memory image = generateImage(params.renderer, params.id);

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', params.name, '", "description":"', params.description, '", "image": "', 'data:text/html;base64,', image, '"}')
                    )
                )
            )
        );
    }

    /**
     * @notice Generate an SVG image for use in the NFT URI.
     */
    function generateImage(INFTRenderer renderer, uint256 id)
        public
        view
        returns (string memory html)
    {
        if (address(renderer) == address(0)) {
            html = "";
        } else {
            html = Base64.encode(bytes(renderer.generateHTML(id)));
        }
    }
}
