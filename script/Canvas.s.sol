// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Canvas} from "../src/Canvas.sol";
import {IConfigurator} from "../src/interfaces/IConfigurator.sol";
import {ICopyright} from "../src/interfaces/ICopyright.sol";
import {IArtwork} from "../src/interfaces/IArtwork.sol";
import {DeployHelper} from "./DeployHelper.sol";

contract DeployCanvas is Script {
    function setUp() public {}

    function run() public {
        string memory configuratorAddress = vm.readFile(
            string(
                abi.encodePacked(
                    "./addresses/",
                    vm.toString(block.chainid),
                    "/Configurator"
                )
            )
        );

        string memory copyrightAddress = vm.readFile(
            string(
                abi.encodePacked(
                    "./addresses/",
                    vm.toString(block.chainid),
                    "/Copyright"
                )
            )
        );
        string memory artworkAddress = vm.readFile(
            string(
                abi.encodePacked(
                    "./addresses/",
                    vm.toString(block.chainid),
                    "/Artwork"
                )
            )
        );

        IConfigurator configurator = IConfigurator(
            DeployHelper.parseAddress(configuratorAddress)
        );
        ICopyright copyright = ICopyright(
            DeployHelper.parseAddress(copyrightAddress)
        );
        IArtwork artwork = IArtwork(DeployHelper.parseAddress(artworkAddress));

        vm.startBroadcast();

        Canvas canvas = new Canvas(configurator, copyright, artwork);

        vm.stopBroadcast();

        vm.writeFile(
            string(
                abi.encodePacked(
                    "./addresses/",
                    vm.toString(block.chainid),
                    "/Canvas"
                )
            ),
            vm.toString(address(canvas))
        );
    }
}
