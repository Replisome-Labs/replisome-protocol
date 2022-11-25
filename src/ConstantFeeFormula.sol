// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IFeeFormula} from "./interfaces/IFeeFormula.sol";

contract ConstantFeeFormula is IFeeFormula {
    uint256 public immutable price;

    constructor(uint256 price_) {
        price = price_;
    }

    function getPrice(uint256, uint256) public view returns (uint256 p) {
        p = price;
    }

    function estimatePrice(bytes calldata, uint256)
        public
        view
        returns (uint256 p)
    {
        p = price;
    }
}
