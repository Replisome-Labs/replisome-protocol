// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IMetadata} from "./IMetadata.sol";

interface IFeeFormula {
    function getPrice(
        IMetadata metadata,
        uint256 metadataId,
        uint256 amount
    ) external view returns (uint256 price);
}
