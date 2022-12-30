// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {IConfigurator} from "../src/interfaces/IConfigurator.sol";
import {ConstantFeeFormula} from "../src/fees/ConstantFeeFormula.sol";
import {LinearFeeFormula} from "../src/fees/LinearFeeFormula.sol";
import {IFeeFormula} from "../src/interfaces/IFeeFormula.sol";
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

        string memory configuratorAddress = vm.readFile(
            string(
                abi.encodePacked(
                    "./addresses/",
                    vm.toString(block.chainid),
                    "/Configurator"
                )
            )
        );

        IConfigurator configurator = IConfigurator(
            DeployHelper.parseAddress(configuratorAddress)
        );

        vm.startBroadcast();

        IFeeFormula constantFeeFormula = new ConstantFeeFormula(
            50000000000000000
        );
        IFeeFormula linearFeeFormula = new LinearFeeFormula(10000000000000000);

        // Configurator configurator = new Configurator();
        configurator.setTreatury(msg.sender);
        configurator.setFeeToken(
            IERC20(DeployHelper.parseAddress(wavaxAddress))
        );
        configurator.setFeeFormula(Action.CopyrightClaim, constantFeeFormula);
        configurator.setFeeFormula(Action.CopyrightWaive, constantFeeFormula);
        configurator.setFeeFormula(Action.ArtworkCopy, linearFeeFormula);
        configurator.setFeeFormula(Action.ArtworkBurn, linearFeeFormula);

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
