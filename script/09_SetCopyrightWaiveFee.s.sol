// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {ConstantFeeFormula} from "../src/fees/ConstantFeeFormula.sol";
import {IConfigurator, Action} from "../src/interfaces/IConfigurator.sol";
import {IFeeFormula} from "../src/interfaces/IFeeFormula.sol";

contract SetCopyrightWaiveFee is Script {
    using stdJson for string;

    function run() public {
        string memory path;
        string memory json;

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

        IFeeFormula feeFormula = new ConstantFeeFormula(50000000000000000);
        configurator.setFeeFormula(Action.CopyrightWaive, feeFormula);

        vm.stopBroadcast();
    }
}
