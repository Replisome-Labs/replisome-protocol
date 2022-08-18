// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CC0Rule} from "../src/rules/CC0Rule.sol";

contract DeployCC0Rule is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        CC0Rule rule = new CC0Rule();

        vm.stopBroadcast();

        vm.writeFile(
            string(
                abi.encodePacked(
                    "./data/",
                    vm.toString(block.chainid),
                    "/CC0Rule"
                )
            ),
            vm.toString(address(rule))
        );
    }
}
