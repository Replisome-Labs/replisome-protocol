// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ICopyrightRenderer} from "../interfaces/ICopyrightRenderer.sol";
import {Base64} from "../libraries/Base64.sol";

library CopyrightDescriptor {
    struct TokenURIParams {
        string name;
        string description;
        uint256 tokenId;
        ICopyrightRenderer renderer;
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(TokenURIParams memory params)
        public
        view
        returns (string memory)
    {
        string memory image = generateSVGImage(params.renderer, params.tokenId);

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
     * @notice Generate an SVG image for use in the ERC721 token URI.
     */
    function generateSVGImage(ICopyrightRenderer renderer, uint256 tokenId)
        public
        view
        returns (string memory svg)
    {
        return Base64.encode(bytes(renderer.generateSVG(tokenId)));
    }
}
