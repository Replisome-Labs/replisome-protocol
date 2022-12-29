// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IFeeFormula} from "../interfaces/IFeeFormula.sol";
import {IMetadata} from "../interfaces/IMetadata.sol";

contract LinearFeeFormula is IFeeFormula {
    uint256 public immutable price;

    constructor(uint256 price_) {
        price = price_;
    }

    function getPrice(
        IMetadata,
        uint256,
        uint256 amount
    ) public view returns (uint256 p) {
        p = price * amount;
    }
}
