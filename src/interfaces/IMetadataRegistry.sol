// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IMetadata} from "./IMetadata.sol";

interface IMetadataRegistry {
    event Registered(IMetadata indexed metadata);

    event Unregistered(IMetadata indexed metadata);

    function isRegistered(IMetadata metadata) external view returns (bool ok);

    function register(IMetadata metadata) external;

    function unregister(IMetadata metadata) external;
}
