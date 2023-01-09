// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {BasicFeesFactory} from "../src/rulesets/BasicFeesFactory.sol";

contract DeployBasicFeesFactory is Script {
    using stdJson for string;

    function run() public {
        vm.startBroadcast();

        BasicFeesFactory ruleset = new BasicFeesFactory();

        vm.stopBroadcast();

        string memory json = "output";

        json.serialize("address", address(ruleset));
        json = json.serialize("startBlock", block.number); // this is not the blockNumber when contract is deployed at

        string memory outputPath = string.concat(
            vm.projectRoot(),
            "/script/output/",
            vm.toString(block.chainid),
            "/BasicFeesFactory.json"
        );

        json.write(outputPath);
    }
}
