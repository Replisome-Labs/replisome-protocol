// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AlreadyRegisteredMetadata, NotRegisteredMetadata} from "./interfaces/Errors.sol";
import {IMetadataRegistry} from "./interfaces/IMetadataRegistry.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";
import {Owned} from "./libraries/Owned.sol";

contract MetadataRegistry is Owned(msg.sender), IMetadataRegistry {
    mapping(IMetadata => bool) public isRegistered;

    function register(IMetadata metadata) external onlyOwner {
        if (isRegistered[metadata]) {
            revert AlreadyRegisteredMetadata(metadata);
        }
        isRegistered[metadata] = true;
        emit Registered(metadata);
    }

    function unregister(IMetadata metadata) external onlyOwner {
        if (!isRegistered[metadata]) {
            revert NotRegisteredMetadata(metadata);
        }
        isRegistered[metadata] = false;
        emit Unregistered(metadata);
    }
}
