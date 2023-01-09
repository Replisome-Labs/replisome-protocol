// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
     * @notice Construct an token URI.
     */
    function constructTokenURI(TokenURIParams memory params)
        public
        view
        returns (string memory)
    {
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        params.name,
                        '", "description":"',
                        params.description,
                        '", "image": "',
                        generateImage(params.renderer, params.id),
                        '"}'
                    )
                )
            );
    }

    /**
     * @notice Generate an image for use in the NFT URI.
     */
    function generateImage(INFTRenderer renderer, uint256 id)
        public
        view
        returns (string memory image)
    {
        if (address(renderer) == address(0)) {
            image = "";
        } else {
            image = string.concat(
                "data:",
                renderer.MIMEType(),
                ";base64,",
                Base64.encode(bytes(renderer.generateFile(id)))
            );
        }
    }
}
