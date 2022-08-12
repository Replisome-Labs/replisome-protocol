// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IMetadata} from "./IMetadata.sol";

interface IMetadataRegistry {
    event Registered(IMetadata indexed metadata);

    event Unregisterd(IMetadata indexed metadata);

    function isRegister(IMetadata metadata) external view returns (bool ok);

    function register(IMetadata metadata) external;

    function unregister(IMetadata metadata) external;
}
