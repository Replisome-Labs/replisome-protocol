// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {Copyright} from "../src/Copyright.sol";
import {IArtwork} from "../src/interfaces/IArtwork.sol";
import {IConfigurator} from "../src/interfaces/IConfigurator.sol";
import {IMetadataRegistry} from "../src/interfaces/IMetadataRegistry.sol";

contract DeployCopyright is Script {
    using stdJson for string;

    function run() public {
        string memory path;
        string memory json;

        path = string.concat(
            vm.projectRoot(),
            "/script/output/",
            vm.toString(block.chainid),
            "/Configurator.json"
        );
        json = vm.readFile(path);
        address configuratorAddress = json.readAddress("address");

        path = string.concat(
            vm.projectRoot(),
            "/script/output/",
            vm.toString(block.chainid),
            "/MetadataRegistry.json"
        );
        json = vm.readFile(path);
        address metadataRegistryAddress = json.readAddress("address");

        IConfigurator configurator = IConfigurator(configuratorAddress);
        IMetadataRegistry metadataRegistry = IMetadataRegistry(
            metadataRegistryAddress
        );

        vm.startBroadcast();

        Copyright copyright = new Copyright(configurator, metadataRegistry);
        IArtwork artwork = copyright.artwork();

        vm.stopBroadcast();

        string memory outputJson;
        string memory outputPath;

        outputJson = "output-copyright";
        outputJson.serialize("address", address(copyright));
        outputJson = outputJson.serialize("startBlock", block.number); // this is not the blockNumber when contract is deployed at
        outputPath = string.concat(
            vm.projectRoot(),
            "/script/output/",
            vm.toString(block.chainid),
            "/Copyright.json"
        );
        outputJson.write(outputPath);

        outputJson = "output-artwork";
        outputJson.serialize("address", address(artwork));
        outputJson = outputJson.serialize("startBlock", block.number); // this is not the blockNumber when contract is deployed at
        outputPath = string.concat(
            vm.projectRoot(),
            "/script/output/",
            vm.toString(block.chainid),
            "/Artwork.json"
        );
        outputJson.write(outputPath);
    }
}
