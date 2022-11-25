// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IFeeFormula {
    function getPrice(uint256 tokenId, uint256 amount)
        external
        view
        returns (uint256 price);

    function estimatePrice(bytes calldata tokenData, uint256 amount)
        external
        view
        returns (uint256 price);
}
