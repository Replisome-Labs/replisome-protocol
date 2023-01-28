// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IMetadata} from "./IMetadata.sol";

interface IFeeFormula {
    /**
     * @dev Returns the price that is computed by `metadata`, `metadataId`, and `amount`
     */
    function getPrice(
        IMetadata metadata,
        uint256 metadataId,
        uint256 amount
    ) external view returns (uint256 price);
}
