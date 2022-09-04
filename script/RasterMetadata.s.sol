// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {RasterMetadata} from "../src/RasterMetadata.sol";
import {ICopyright} from "../src/interfaces/ICopyright.sol";
import {IMetadataRegistry} from "../src/interfaces/IMetadataRegistry.sol";
import {DeployHelper} from "./DeployHelper.sol";

contract DeployRasterMetadata is Script {
    function setUp() public {}

    function run() public {
        string memory metadataRegistryAddress = vm.readFile(
            string(
                abi.encodePacked(
                    "./data/",
                    vm.toString(block.chainid),
                    "/MetadataRegistry"
                )
            )
        );
        string memory copyrightAddress = vm.readFile(
            string(
                abi.encodePacked(
                    "./data/",
                    vm.toString(block.chainid),
                    "/Copyright"
                )
            )
        );

        IMetadataRegistry registry = IMetadataRegistry(
            DeployHelper.parseAddress(metadataRegistryAddress)
        );
        ICopyright copyright = ICopyright(
            DeployHelper.parseAddress(copyrightAddress)
        );

        vm.startBroadcast();

        RasterMetadata metadata = new RasterMetadata(copyright, 16, 16);
        registry.register(metadata);

        vm.stopBroadcast();

        vm.writeFile(
            string(
                abi.encodePacked(
                    "./data/",
                    vm.toString(block.chainid),
                    "/RasterMetadata16x16"
                )
            ),
            vm.toString(address(metadata))
        );
    }
}
