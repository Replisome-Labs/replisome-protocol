// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface INFTRenderer {
    function MIMEType() external view returns (string memory mimeType);

    function generateFile(uint256 id)
        external
        view
        returns (string memory file);
}
