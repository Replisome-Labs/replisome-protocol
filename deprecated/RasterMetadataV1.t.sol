// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {RasterMetadataV1} from "./RasterMetadataV1.sol";
import {Property, Layer, TransformParam} from "../interfaces/Structs.sol";
import {IRuleset} from "../interfaces/IRuleset.sol";
import {MockCopyright} from "../../test/mock/MockCopyright.sol";

contract RasterMetadataV1Test is Test {
    using stdStorage for StdStorage;

    event Created(uint256 indexed metadataId);

    MockCopyright public copyright;
    RasterMetadataV1 public metadata;

    function setUp() public {
        copyright = new MockCopyright();
        metadata = new RasterMetadataV1(copyright, 16, 16, 16);
    }

    function testCreatWithoutLayers() public {
        Layer[] memory layers = new Layer[](0);
        bytes memory drawings = abi.encodePacked(
            uint32(0),
            uint32(0),
            uint32(1),
            uint32(0),
            uint32(0),
            uint32(0),
            uint32(0),
            uint8(0),
            uint8(0),
            uint8(0),
            type(uint8).max
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
            uint32(0),
            uint32(0),
            uint32(1),
            uint32(0),
            uint32(0),
            uint32(0),
            uint32(0),
            uint8(0),
            uint8(0),
            type(uint8).max,
            type(uint8).max
        );

        vm.expectEmit(true, false, false, false);
        emit Created(2);

        uint256 id = metadata.create(layers, drawings);

        emit log(metadata.generateSVG(id));
    }

    function mockLayer() public {
        Layer[] memory layers = new Layer[](0);
        bytes memory drawings = abi.encodePacked(
            uint32(8),
            uint32(8),
            uint32(1),
            uint32(0),
            uint32(0),
            uint32(0),
            uint32(0),
            uint8(0),
            type(uint8).max,
            uint8(0),
            type(uint8).max
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
