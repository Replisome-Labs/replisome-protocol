// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {MetadataRegistry} from "../src/MetadataRegistry.sol";

contract DeployMetadataRegistry is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        MetadataRegistry metadataRegistry = new MetadataRegistry();

        vm.stopBroadcast();

        vm.writeFile(
            string(
                abi.encodePacked(
                    "./addresses/",
                    vm.toString(block.chainid),
                    "/MetadataRegistry"
                )
            ),
            vm.toString(address(metadataRegistry))
        );
    }
}
