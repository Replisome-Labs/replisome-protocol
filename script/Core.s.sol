// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Configurator} from "../src/Configurator.sol";
import {MetadataRegistry} from "../src/MetadataRegistry.sol";
import {Copyright} from "../src/Copyright.sol";
import {Artwork} from "../src/Artwork.sol";

contract DeployCore is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        Configurator configurator = new Configurator();
        MetadataRegistry metadataRegistry = new MetadataRegistry();
        Copyright copyright = new Copyright(configurator, metadataRegistry);
        Artwork artwork = new Artwork(configurator, copyright);

        vm.stopBroadcast();

        vm.writeFile(
            string(
                abi.encodePacked(
                    "./data/",
                    vm.toString(block.chainid),
                    "/Configurator"
                )
            ),
            vm.toString(address(configurator))
        );
        vm.writeFile(
            string(
                abi.encodePacked(
                    "./data/",
                    vm.toString(block.chainid),
                    "/MetadataRegistry"
                )
            ),
            vm.toString(address(metadataRegistry))
        );
        vm.writeFile(
            string(
                abi.encodePacked(
                    "./data/",
                    vm.toString(block.chainid),
                    "/Copyright"
                )
            ),
            vm.toString(address(copyright))
        );
        vm.writeFile(
            string(
                abi.encodePacked(
                    "./data/",
                    vm.toString(block.chainid),
                    "/Artwork"
                )
            ),
            vm.toString(address(artwork))
        );
    }
}
