// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {RasterMetadata} from "../src/RasterMetadata.sol";
import {Property, Layer, TransformParam} from "../src/interfaces/Structs.sol";
import {IRule} from "../src/interfaces/IRule.sol";
import {MockCopyright} from "./mock/MockCopyright.sol";

contract RasterMetadataTest is Test {
    using stdStorage for StdStorage;

    event Created(uint256 indexed metadataId);

    MockCopyright public copyright;
    RasterMetadata public metadata;

    function setUp() public {
        copyright = new MockCopyright();
        metadata = new RasterMetadata(copyright, 16, 16);
    }

    function testCreatWithoutLayers() public {
        Layer[] memory layers = new Layer[](0);
        bytes memory drawings = abi.encodePacked(
            uint8(1),
            uint8(0),
            uint8(0),
            uint8(0),
            type(uint8).max
        );
        for (uint256 i = 0; i < 256; i++) {
            if (i == 0 || i == 20 || i == 30) {
                drawings = abi.encodePacked(drawings, uint8(1));
            } else {
                drawings = abi.encodePacked(drawings, uint8(0));
            }
        }

        vm.expectEmit(true, false, false, false);
        emit Created(1);

        uint256 id = metadata.create(layers, drawings);

        emit log_bytes(metadata.readRawData(id));
        emit log(metadata.generateSVG(id));
    }

    function testCreateWithLayers() public {
        mockLayer();
        Layer[] memory layers = new Layer[](1);
        layers[0] = Layer({tokenId: 1, transforms: new TransformParam[](0)});
        bytes memory drawings = abi.encodePacked(
            uint8(1),
            uint8(0),
            uint8(0),
            type(uint8).max,
            type(uint8).max
        );
        for (uint256 i = 0; i < 256; i++) {
            if (i == 10) {
                drawings = abi.encodePacked(drawings, uint8(1));
            } else {
                drawings = abi.encodePacked(drawings, uint8(0));
            }
        }

        vm.expectEmit(true, false, false, false);
        emit Created(2);

        uint256 id = metadata.create(layers, drawings);

        emit log_bytes(metadata.readRawData(id));
        emit log(metadata.generateSVG(id));
    }

    function mockLayer() public {
        Layer[] memory layers = new Layer[](0);
        bytes memory drawings = abi.encodePacked(
            uint8(1),
            uint8(0),
            uint8(0),
            uint8(0),
            type(uint8).max
        );
        for (uint256 i = 0; i < 256; i++) {
            if (i == 0) {
                drawings = abi.encodePacked(drawings, uint8(1));
            } else {
                drawings = abi.encodePacked(drawings, uint8(0));
            }
        }

        uint256 id = metadata.create(layers, drawings);

        Property memory property = Property({
            creator: address(this),
            rule: IRule(address(0)),
            metadata: metadata,
            metadataId: id
        });
        copyright.setPropertyInfo(1, property);
    }
}
