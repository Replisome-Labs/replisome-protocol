// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {CC0Ruleset} from "../src/rulesets/CC0Ruleset.sol";

contract DeployCC0Ruleset is Script {
    using stdJson for string;

    function run() public {
        vm.startBroadcast();

        CC0Ruleset ruleset = new CC0Ruleset();

        vm.stopBroadcast();

        string memory json = "output";

        json.serialize("address", address(ruleset));
        json = json.serialize("startBlock", block.number); // this is not the blockNumber when contract is deployed at

        string memory outputPath = string.concat(
            vm.projectRoot(),
            "/script/output/",
            vm.toString(block.chainid),
            "/CC0Ruleset.json"
        );

        json.write(outputPath);
    }
}
