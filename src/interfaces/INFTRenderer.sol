// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface INFTRenderer {
    /**
     * @dev Returns mime type.
     */
    function MIMEType() external view returns (string memory mimeType);

    /**
     * @dev generate a file of `id` that can be rendered on brower.
     */
    function generateFile(uint256 id)
        external
        view
        returns (string memory file);
}
