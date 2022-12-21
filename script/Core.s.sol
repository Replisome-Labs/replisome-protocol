// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Action} from "../src/interfaces/Structs.sol";
import {IArtwork} from "../src/interfaces/IArtwork.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IFeeFormula} from "../src/interfaces/IFeeFormula.sol";
import {INFTRenderer} from "../src/interfaces/INFTRenderer.sol";
import {ConstantFeeFormula} from "../src/fees/ConstantFeeFormula.sol";
import {LinearFeeFormula} from "../src/fees/LinearFeeFormula.sol";
import {CopyrightRenderer} from "../src/utils/CopyrightRenderer.sol";
import {Configurator} from "../src/Configurator.sol";
import {MetadataRegistry} from "../src/MetadataRegistry.sol";
import {Copyright} from "../src/Copyright.sol";
import {DeployHelper} from "./DeployHelper.sol";

contract DeployCore is Script {
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

        // configurator
        IFeeFormula constantFeeFormula = new ConstantFeeFormula(
            50000000000000000
        );
        IFeeFormula linearFeeFormula = new LinearFeeFormula(10000000000000000);

        Configurator configurator = new Configurator();
        configurator.setTreatury(msg.sender);
        configurator.setFeeToken(
            IERC20(DeployHelper.parseAddress(wavaxAddress))
        );
        configurator.setFeeFormula(Action.CopyrightClaim, constantFeeFormula);
        configurator.setFeeFormula(Action.CopyrightWaive, constantFeeFormula);
        configurator.setFeeFormula(Action.ArtworkCopy, linearFeeFormula);
        configurator.setFeeFormula(Action.ArtworkBurn, linearFeeFormula);

        // MetadataRegistry
        MetadataRegistry metadataRegistry = new MetadataRegistry();

        // Copyright & Artwork
        Copyright copyright = new Copyright(configurator, metadataRegistry);
        IArtwork artwork = copyright.artwork();

        INFTRenderer copyrightRenderer = new CopyrightRenderer(copyright);
        configurator.setCopyrightRenderer(copyrightRenderer);

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
        vm.writeFile(
            string(
                abi.encodePacked(
                    "./addresses/",
                    vm.toString(block.chainid),
                    "/MetadataRegistry"
                )
            ),
            vm.toString(address(metadataRegistry))
        );
        vm.writeFile(
            string(
                abi.encodePacked(
                    "./addresses/",
                    vm.toString(block.chainid),
                    "/Copyright"
                )
            ),
            vm.toString(address(copyright))
        );
        vm.writeFile(
            string(
                abi.encodePacked(
                    "./addresses/",
                    vm.toString(block.chainid),
                    "/Artwork"
                )
            ),
            vm.toString(address(artwork))
        );
    }
}
