// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {IConfigurator} from "../src/interfaces/IConfigurator.sol";

contract SetTreatury is Script {
    using stdJson for string;

    function run() public {
        string memory path;
        string memory json;

        path = string.concat(
            vm.projectRoot(),
            "/script/input/",
            vm.toString(block.chainid),
            "/addresses.json"
        );
        json = vm.readFile(path);
        address treaturyAddress = json.readAddress("Treatury");

        path = string.concat(
            vm.projectRoot(),
            "/script/output/",
            vm.toString(block.chainid),
            "/Configurator.json"
        );
        json = vm.readFile(path);
        address configuratorAddress = json.readAddress("address");

        IConfigurator configurator = IConfigurator(configuratorAddress);

        vm.startBroadcast();

        configurator.setTreatury(treaturyAddress);

        vm.stopBroadcast();
    }
}
