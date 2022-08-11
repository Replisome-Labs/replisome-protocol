// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC165} from "./IERC165.sol";

interface IMetadata is IERC165 {
    function readAsSvg(uint256 metadataId)
        external
        view
        returns (string memory svg);

    function readAsBytes(uint256 metadataId)
        external
        view
        returns (bytes memory raw);

    function verify() external view returns (uint256 metadataId);

    function create() external returns (uint256 metadataId);
}
