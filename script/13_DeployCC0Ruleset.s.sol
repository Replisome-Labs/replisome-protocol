// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {CC0} from "../src/rulesets/CC0.sol";

contract DeployCC0Ruleset is Script {
    using stdJson for string;

    function run() public {
        vm.startBroadcast();

        CC0 ruleset = new CC0();

        vm.stopBroadcast();

        string memory json = "output";

        json.serialize("address", address(ruleset));
        json = json.serialize("startBlock", block.number); // this is not the blockNumber when contract is deployed at

        string memory outputPath = string.concat(
            vm.projectRoot(),
            "/script/output/",
            vm.toString(block.chainid),
            "/CC0.json"
        );

        json.write(outputPath);
    }
}
