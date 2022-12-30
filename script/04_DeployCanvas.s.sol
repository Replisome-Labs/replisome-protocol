// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {Canvas} from "../src/Canvas.sol";
import {ICopyright} from "../src/interfaces/ICopyright.sol";
import {IArtwork} from "../src/interfaces/IArtwork.sol";
import {IConfigurator} from "../src/interfaces/IConfigurator.sol";

contract DeployCanvas is Script {
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

        path = string.concat(
            vm.projectRoot(),
            "/script/output/",
            vm.toString(block.chainid),
            "/Copyright.json"
        );
        json = vm.readFile(path);
        address copyrightAddress = json.readAddress("address");

        path = string.concat(
            vm.projectRoot(),
            "/script/output/",
            vm.toString(block.chainid),
            "/Artwork.json"
        );
        json = vm.readFile(path);
        address artworkAddress = json.readAddress("address");

        IConfigurator configurator = IConfigurator(configuratorAddress);
        ICopyright copyright = ICopyright(copyrightAddress);
        IArtwork artwork = IArtwork(artworkAddress);

        vm.startBroadcast();

        Canvas canvas = new Canvas(configurator, copyright, artwork);

        vm.stopBroadcast();

        string memory outputJson;
        string memory outputPath;

        outputJson = "output";
        outputJson.serialize("address", address(canvas));
        outputJson = outputJson.serialize("startBlock", block.number); // this is not the blockNumber when contract is deployed at
        outputPath = string.concat(
            vm.projectRoot(),
            "/script/output/",
            vm.toString(block.chainid),
            "/Canvas.json"
        );
        outputJson.write(outputPath);
    }
}
