// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Configurator} from "../src/Configurator.sol";
import {ConstantFeeFormula} from "../src/ConstantFeeFormula.sol";
import {Action} from "../src/interfaces/Structs.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {DeployHelper} from "./DeployHelper.sol";

contract DeployConfigurator is Script {
    function setUp() public {}

    function run() public {
        string memory wavaxAddress = vm.readFile(
            string(
                abi.encodePacked(
                    "./addresses/",
                    vm.toString(block.chainid),
                    "/WAVAX"
                )
            )
        );

        vm.startBroadcast();

        Configurator configurator = new Configurator();
        ConstantFeeFormula feeFormula = new ConstantFeeFormula(
            100000000000000000
        );

        configurator.setTreatury(msg.sender);
        configurator.setFeeToken(
            IERC20(DeployHelper.parseAddress(wavaxAddress))
        );
        configurator.setFeeFormula(Action.CopyrightClaim, feeFormula);
        configurator.setFeeFormula(Action.CopyrightWaive, feeFormula);
        configurator.setFeeFormula(Action.ArtworkCopy, feeFormula);
        configurator.setFeeFormula(Action.ArtworkBurn, feeFormula);

        vm.stopBroadcast();

        vm.writeFile(
            string(
                abi.encodePacked(
                    "./addresses/",
                    vm.toString(block.chainid),
                    "/Configurator"
                )
            ),
            vm.toString(address(configurator))
        );
    }
}
