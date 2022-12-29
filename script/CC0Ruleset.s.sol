// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {CC0Ruleset} from "../src/rulesets/CC0Ruleset.sol";

contract DeployCC0Ruleset is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        CC0Ruleset ruleset = new CC0Ruleset();

        vm.stopBroadcast();

        vm.writeFile(
            string(
                abi.encodePacked(
                    "./addresses/",
                    vm.toString(block.chainid),
                    "/CC0Ruleset"
                )
            ),
            vm.toString(address(ruleset))
        );
    }
}
