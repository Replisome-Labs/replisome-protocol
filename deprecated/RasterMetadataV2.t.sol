// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {RasterMetadataV2} from "./RasterMetadataV2.sol";
import {Property, Layer, TransformParam} from "../interfaces/Structs.sol";
import {IRuleset} from "../interfaces/IRuleset.sol";
import {MockCopyright} from "../../test/mock/MockCopyright.sol";

contract RasterMetadataV2Test is Test {
    using stdStorage for StdStorage;

    event Created(uint256 indexed metadataId);

    MockCopyright public copyright;
    RasterMetadataV2 public metadata;

    function setUp() public {
        copyright = new MockCopyright();
        metadata = new RasterMetadataV2(copyright, 16, 16);
    }

    function testCreatWithoutLayers() public {
        Layer[] memory layers = new Layer[](0);
        bytes memory drawings = abi.encodePacked(
            uint256(1),
            uint256(1),
            uint8(0),
            uint8(0),
            uint8(0),
            type(uint8).max,
            bytes28(0)
        );

        vm.expectEmit(true, false, false, false);
        emit Created(1);

        uint256 id = metadata.create(layers, drawings);

        emit log(metadata.generateSVG(id));
    }

    function testCreateWithLayers() public {
        mockLayer();
        Layer[] memory layers = new Layer[](1);
        layers[0] = Layer({tokenId: 1, transforms: new TransformParam[](0)});
        bytes memory drawings = abi.encodePacked(
            uint256(1),
            uint256(1),
            uint8(0),
            uint8(0),
            type(uint8).max,
            type(uint8).max,
            bytes28(0)
        );

        vm.expectEmit(true, false, false, false);
        emit Created(2);

        uint256 id = metadata.create(layers, drawings);

        emit log(metadata.generateSVG(id));
    }

    function mockLayer() public {
        Layer[] memory layers = new Layer[](0);
        bytes memory drawings = abi.encodePacked(
            uint256(8),
            uint256(8),
            uint8(0),
            type(uint8).max,
            type(uint8).max,
            type(uint8).max,
            bytes28(0)
        );

        uint256 id = metadata.create(layers, drawings);

        Property memory property = Property({
            creator: address(this),
            ruleset: IRuleset(address(0)),
            metadata: metadata,
            metadataId: id
        });
        copyright.setPropertyInfo(1, property);
    }
}
