// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {MetadataRegistry} from "../src/MetadataRegistry.sol";

contract DeployMetadataRegistry is Script {
    using stdJson for string;

    function run() public {
        vm.startBroadcast();

        MetadataRegistry metadataRegistry = new MetadataRegistry();

        vm.stopBroadcast();

        string memory json = "output";

        json.serialize("address", address(metadataRegistry));
        json = json.serialize("startBlock", block.number); // this is not the blockNumber when contract is deployed at

        string memory outputPath = string.concat(
            vm.projectRoot(),
            "/script/output/",
            vm.toString(block.chainid),
            "/MetadataRegistry.json"
        );

        json.write(outputPath);
    }
}
