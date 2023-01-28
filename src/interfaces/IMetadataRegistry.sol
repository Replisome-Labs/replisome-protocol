// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IMetadata} from "./IMetadata.sol";

interface IMetadataRegistry {
    /**
     * @dev Emits when registering a metadata
     */
    event Registered(IMetadata indexed metadata);

    /**
     * @dev Emits when unregistering a metadata
     */
    event Unregistered(IMetadata indexed metadata);

    /**
     * @dev Returns true if the `metadata` has been registered
     */
    function isRegistered(IMetadata metadata) external view returns (bool ok);

    /**
     * @dev register a `metadata`
     * Emits a {Registered} event
     */
    function register(IMetadata metadata) external;

    /**
     * @dev unregister a `metadata`
     * Emits a {Unregistered} event
     */
    function unregister(IMetadata metadata) external;
}
