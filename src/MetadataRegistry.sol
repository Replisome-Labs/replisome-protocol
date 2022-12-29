// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AlreadyRegisteredMetadata, NotRegisteredMetadata} from "./interfaces/Errors.sol";
import {IMetadataRegistry} from "./interfaces/IMetadataRegistry.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";
import {Owned} from "./libraries/Owned.sol";
import {ERC165Checker} from "./libraries/ERC165Checker.sol";

contract MetadataRegistry is Owned(msg.sender), IMetadataRegistry {
    using ERC165Checker for address;

    mapping(IMetadata => bool) public isRegistered;

    function register(IMetadata metadata) external onlyOwner {
        if (isRegistered[metadata]) {
            revert AlreadyRegisteredMetadata(metadata);
        }
        if (metadata.supportsInterface(type(IMetadata).interfaceId)) {
            isRegistered[metadata] = true;
            emit Registered(metadata);
        }
    }

    function unregister(IMetadata metadata) external onlyOwner {
        if (!isRegistered[metadata]) {
            revert NotRegisteredMetadata(metadata);
        }
        isRegistered[metadata] = false;
        emit Unregistered(metadata);
    }
}
