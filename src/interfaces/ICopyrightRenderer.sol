// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ICopyrightRenderer {
    function generateSVG(uint256 tokenId)
        external
        view
        returns (string memory svg);
}
