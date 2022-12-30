// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {Configurator} from "../src/Configurator.sol";

contract DeployConfigurator is Script {
    using stdJson for string;

    function run() public {
        vm.startBroadcast();

        Configurator configurator = new Configurator();

        vm.stopBroadcast();

        string memory json = "output";

        json.serialize("address", address(configurator));
        json = json.serialize("startBlock", block.number); // this is not the blockNumber when contract is deployed at

        string memory outputPath = string.concat(
            vm.projectRoot(),
            "/script/output/",
            vm.toString(block.chainid),
            "/Configurator.json"
        );

        json.write(outputPath);
    }
}
