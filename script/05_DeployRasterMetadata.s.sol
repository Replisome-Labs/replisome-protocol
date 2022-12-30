// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {RasterMetadata} from "../src/RasterMetadata.sol";
import {ICopyright} from "../src/interfaces/ICopyright.sol";
import {IMetadataRegistry} from "../src/interfaces/IMetadataRegistry.sol";

contract DeployRasterMetadata is Script {
    using stdJson for string;

    function run() public {
        string memory path;
        string memory json;

        path = string.concat(
            vm.projectRoot(),
            "/script/output/",
            vm.toString(block.chainid),
            "/Copyright.json"
        );
        json = vm.readFile(path);
        address copyrightAddress = json.readAddress("address");

        path = string.concat(
            vm.projectRoot(),
            "/script/output/",
            vm.toString(block.chainid),
            "/MetadataRegistry.json"
        );
        json = vm.readFile(path);
        address metadataRegistryAddress = json.readAddress("address");

        ICopyright copyright = ICopyright(copyrightAddress);
        IMetadataRegistry metadataRegistry = IMetadataRegistry(
            metadataRegistryAddress
        );

        vm.startBroadcast();

        RasterMetadata metadata = new RasterMetadata(copyright);
        metadataRegistry.register(metadata);

        vm.stopBroadcast();

        string memory outputJson;
        string memory outputPath;

        outputJson = "output";
        outputJson.serialize("address", address(metadata));
        outputJson = outputJson.serialize("startBlock", block.number); // this is not the blockNumber when contract is deployed at
        outputPath = string.concat(
            vm.projectRoot(),
            "/script/output/",
            vm.toString(block.chainid),
            "/RasterMetadata.json"
        );
        outputJson.write(outputPath);
    }
}
