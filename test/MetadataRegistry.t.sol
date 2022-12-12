// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {MetadataRegistry} from "../src/MetadataRegistry.sol";
import {IMetadata} from "../src/interfaces/IMetadata.sol";
import {Unauthorized, AlreadyRegisteredMetadata, NotRegisteredMetadata} from "../src/interfaces/Errors.sol";
import {MockMetadata} from "./mock/MockMetadata.sol";

contract MetadataRegistryTest is Test {
    using stdStorage for StdStorage;

    event Registered(IMetadata indexed metadata);

    event Unregistered(IMetadata indexed metadata);

    MetadataRegistry public metadataRegistry;

    address public constant prankAddress = address(0);
    IMetadata public mockMetadata;

    function setUp() public {
        metadataRegistry = new MetadataRegistry();
        mockMetadata = new MockMetadata();
    }

    function testRegister() public {
        vm.expectEmit(true, false, false, false);
        emit Registered(mockMetadata);
        metadataRegistry.register(mockMetadata);
        assertEq(metadataRegistry.isRegistered(mockMetadata), true);
    }

    function testRegisterTwice() public {
        stdstore
            .target(address(metadataRegistry))
            .sig(metadataRegistry.isRegistered.selector)
            .with_key(address(mockMetadata))
            .checked_write(true);
        vm.expectRevert(
            abi.encodeWithSelector(
                AlreadyRegisteredMetadata.selector,
                mockMetadata
            )
        );
        metadataRegistry.register(mockMetadata);
    }

    function testRegisterAsNotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(Unauthorized.selector, prankAddress)
        );
        vm.startPrank(prankAddress);
        metadataRegistry.register(mockMetadata);
        vm.stopPrank();
    }

    function testUnregister() public {
        stdstore
            .target(address(metadataRegistry))
            .sig(metadataRegistry.isRegistered.selector)
            .with_key(address(mockMetadata))
            .checked_write(true);
        vm.expectEmit(true, false, false, false);
        emit Unregistered(mockMetadata);
        metadataRegistry.unregister(mockMetadata);
        assertEq(metadataRegistry.isRegistered(mockMetadata), false);
    }

    function testUnregisterTwice() public {
        stdstore
            .target(address(metadataRegistry))
            .sig(metadataRegistry.isRegistered.selector)
            .with_key(address(mockMetadata))
            .checked_write(false);
        vm.expectRevert(
            abi.encodeWithSelector(NotRegisteredMetadata.selector, mockMetadata)
        );
        metadataRegistry.unregister(mockMetadata);
    }

    function testUnregisterAsNotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(Unauthorized.selector, prankAddress)
        );
        vm.startPrank(prankAddress);
        metadataRegistry.unregister(mockMetadata);
        vm.stopPrank();
    }
}
