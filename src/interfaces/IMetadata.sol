// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC165} from "./IERC165.sol";
import {ICopyright} from "./ICopyright.sol";
import {INFTRenderer} from "./INFTRenderer.sol";

interface IMetadata is IERC165, INFTRenderer {
    /**
     * @dev Emits when metadata is created.
     */
    event Created(uint256 indexed metadataId, bytes rawData);

    /**
     * @dev Returns the address of copyright.
     */
    function copyright() external view returns (ICopyright target);

    /**
     * @dev Returns the amount of metadata in existence.
     */
    function totalSupply() external view returns (uint256 amount);

    /**
     * @dev Returns the raw data of the `metadataId` metadata.
     */
    function generateRawData(uint256 metadataId)
        external
        view
        returns (bytes memory raw);

    /**
     * @dev Returns true if the `metadata` is supported by this metadata contract.
     */
    function supportsMetadata(IMetadata metadata)
        external
        view
        returns (bool ok);

    /**
     * @dev Returns true if the `metadataId` metadata exists.
     */
    function exists(uint256 metadataId) external view returns (bool ok);

    /**
     * @dev Returns the width of the `metadataId` metadata.
     */
    function width(uint256 metadataId) external view returns (uint256 w);

    /**
     * @dev Returns the height of the `metadataId` metadata.
     */
    function height(uint256 metadataId) external view returns (uint256 h);

    /**
     * @dev Returns id and amount of tokens that ara composed into the `metadataId` metadata.
     */
    function getIngredients(uint256 metadataId)
        external
        view
        returns (uint256[] memory ids, uint256[] memory amounts);

    /**
     * @dev Returns the amount of the `tokenId` token that ara composed into the `metadataId` metadata.
     */
    function getIngredientAmount(uint256 metadataId, uint256 tokenId)
        external
        view
        returns (uint256 amount);

    /**
     * @dev Returns id of the metadata that is encoded as data.
     */
    function verify(bytes calldata data) external returns (uint256 metadataId);

    /**
     * @dev create metadata.
     * Emits a {Created} event.
     */
    function create(bytes calldata data) external returns (uint256 metadataId);
}
