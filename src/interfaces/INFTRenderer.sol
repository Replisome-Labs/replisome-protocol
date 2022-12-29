// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface INFTRenderer {
    function generateHTML(uint256 id)
        external
        view
        returns (string memory html);
}
