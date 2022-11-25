// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CC0Ruleset} from "../src/rulesets/CC0Ruleset.sol";

contract DeployCC0Rule is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        CC0Ruleset rule = new CC0Ruleset();

        vm.stopBroadcast();

        vm.writeFile(
            string(
                abi.encodePacked(
                    "./data/",
                    vm.toString(block.chainid),
                    "/CC0Ruleset"
                )
            ),
            vm.toString(address(rule))
        );
    }
}
