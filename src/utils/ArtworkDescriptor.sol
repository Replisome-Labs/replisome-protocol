// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IMetadata} from "../interfaces/IMetadata.sol";
import {Base64} from "../libraries/Base64.sol";

library ArtworkDescriptor {
    struct TokenURIParams {
        string name;
        string description;
        IMetadata metadata;
        uint256 metadataId;
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(TokenURIParams memory params)
        public
        view
        returns (string memory)
    {
        string memory image = generateSVGImage(
            params.metadata,
            params.metadataId
        );

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
    function generateSVGImage(IMetadata metadata, uint256 metadataId)
        public
        view
        returns (string memory svg)
    {
        return Base64.encode(bytes(metadata.generateSVG(metadataId)));
    }
}
