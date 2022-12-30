// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {IConfigurator} from "../src/interfaces/IConfigurator.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

contract SetFeeToken is Script {
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
        address feeTokenAddress = json.readAddress("FeeToken");

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

        configurator.setFeeToken(IERC20(feeTokenAddress));

        vm.stopBroadcast();
    }
}
