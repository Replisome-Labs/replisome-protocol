// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface INFTRenderer {
    function generateHTML(uint256 id)
        external
        view
        returns (string memory html);
}
