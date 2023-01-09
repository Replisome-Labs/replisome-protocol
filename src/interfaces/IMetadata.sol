// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC165} from "./IERC165.sol";
import {ICopyright} from "./ICopyright.sol";
import {INFTRenderer} from "./INFTRenderer.sol";

interface IMetadata is IERC165, INFTRenderer {
    event Created(uint256 indexed metadataId, bytes rawData);

    function copyright() external view returns (ICopyright target);

    function totalSupply() external view returns (uint256 amount);

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

    function getColors(uint256 metadataId)
        external
        view
        returns (bytes4[] memory colors);

    function getIngredients(uint256 metadataId)
        external
        view
        returns (uint256[] memory ids, uint256[] memory amounts);

    function verify(bytes calldata data) external returns (uint256 metadataId);

    function create(bytes calldata data) external returns (uint256 metadataId);
}
