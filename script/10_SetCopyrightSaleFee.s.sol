// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {IConfigurator, Action} from "../src/interfaces/IConfigurator.sol";
import {IFeeFormula} from "../src/interfaces/IFeeFormula.sol";

contract SetCopyrightSaleFee is Script {
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

        configurator.setFeeFormula(
            Action.CopyrightSale,
            IFeeFormula(address(0))
        );

        vm.stopBroadcast();
    }
}
