// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {Copyright} from "../src/Copyright.sol";
import {IArtwork} from "../src/interfaces/IArtwork.sol";
import {IConfigurator} from "../src/interfaces/IConfigurator.sol";
import {IMetadataRegistry} from "../src/interfaces/IMetadataRegistry.sol";
import {DeployHelper} from "./DeployHelper.sol";

contract DeployCopyright is Script {
    function setUp() public {}

    function run() public {
        string memory configuratorAddress = vm.readFile(
            string(
                abi.encodePacked(
                    "./addresses/",
                    vm.toString(block.chainid),
                    "/Configurator"
                )
            )
        );

        string memory metadataRegistryAddress = vm.readFile(
            string(
                abi.encodePacked(
                    "./addresses/",
                    vm.toString(block.chainid),
                    "/MetadataRegistry"
                )
            )
        );

        IConfigurator configurator = IConfigurator(
            DeployHelper.parseAddress(configuratorAddress)
        );
        IMetadataRegistry metadataRegistry = IMetadataRegistry(
            DeployHelper.parseAddress(metadataRegistryAddress)
        );

        vm.startBroadcast();

        Copyright copyright = new Copyright(configurator, metadataRegistry);
        IArtwork artwork = copyright.artwork();

        vm.stopBroadcast();

        vm.writeFile(
            string(
                abi.encodePacked(
                    "./addresses/",
                    vm.toString(block.chainid),
                    "/Copyright"
                )
            ),
            vm.toString(address(copyright))
        );

        vm.writeFile(
            string(
                abi.encodePacked(
                    "./addresses/",
                    vm.toString(block.chainid),
                    "/Artwork"
                )
            ),
            vm.toString(address(artwork))
        );
    }
}
