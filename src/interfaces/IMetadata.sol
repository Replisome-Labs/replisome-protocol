// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Layer} from "./Structs.sol";
import {IERC165} from "./IERC165.sol";

interface IMetadata is IERC165 {
    event Created(uint256 indexed metadataId);

    function generateSVG(uint256 metadataId)
        external
        view
        returns (string memory svg);

    function generateRawData(uint256 metadataId)
        external
        view
        returns (bytes memory raw);

    function supportsMetadata(IMetadata metadata)
        external
        view
        returns (bool ok);

    function exists(uint256 metadataId) external view returns (bool ok);

    function width(uint256 metadataId) external view returns (uint256 w);

    function height(uint256 metadataId) external view returns (uint256 h);

    function getIngredients(uint256 metadataId)
        external
        view
        returns (uint256[] memory ids, uint256[] memory amounts);

    function verify(bytes calldata data)
        external
        returns (uint256 metadataId);

    function create(bytes calldata data)
        external
        returns (uint256 metadataId);
}
