// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {RasterMetadata} from "../src/RasterMetadata.sol";
import {Property, Layer, Rotate, Flip} from "../src/interfaces/Structs.sol";
import {IRule} from "../src/interfaces/IRule.sol";
import {MockCopyright} from "./mock/MockCopyright.sol";

contract RasterMetadataTest is Test {
    using stdStorage for StdStorage;

    event Created(uint256 indexed metadataId);

    MockCopyright public copyright;
    RasterMetadata public metadata;

    function setUp() public {
        copyright = new MockCopyright();
        metadata = new RasterMetadata(copyright);
    }

    function testCreatWithoutLayers() public {
        Layer[] memory layers = new Layer[](0);
        bytes4[] memory colors = new bytes4[](1);
        colors[0] = hex"000000FF";

        bytes memory drawing = new bytes(256);
        for (uint256 i = 0; i < 256; i++) {
            if (i == 10) {
                drawing[i] = bytes1(uint8(1));
            } else {
                drawing[i] = bytes1(uint8(0));
            }
        }
        bytes memory data =
            abi.encode(uint256(16), uint256(16), layers, colors, drawing);

        vm.expectEmit(true, false, false, false);
        emit Created(1);

        uint256 id = metadata.create(data);

        emit log_bytes(metadata.generateRawData(id));
        emit log(metadata.generateSVG(id));
    }

    function testCreateWithLayers() public {
        mockLayer();

        Layer[] memory layers = new Layer[](1);
        layers[0] = Layer({
            tokenId: 1,
            rotate: Rotate.D0,
            flip: Flip.None,
            translateX: 0,
            translateY: 0
        });
        bytes4[] memory colors = new bytes4[](1);
        colors[0] = hex"000000FF";

        bytes memory drawing = new bytes(256);
        for (uint256 i = 0; i < 256; i++) {
            if (i == 30) {
                drawing[i] = bytes1(uint8(1));
            } else {
                drawing[i] = bytes1(uint8(0));
            }
        }
        bytes memory data =
            abi.encode(uint256(16), uint256(16), layers, colors, drawing);

        vm.expectEmit(true, false, false, false);
        emit Created(2);

        uint256 id = metadata.create(data);

        emit log_bytes(metadata.generateRawData(id));
        emit log(metadata.generateSVG(id));
    }

    function mockLayer() public {
        Layer[] memory layers = new Layer[](0);
        bytes4[] memory colors = new bytes4[](1);
        colors[0] = hex"000000FF";

        bytes memory drawing = new bytes(256);
        for (uint256 i = 0; i < 256; i++) {
            if (i == 20) {
                drawing[i] = bytes1(uint8(1));
            } else {
                drawing[i] = bytes1(uint8(0));
            }
        }
        bytes memory data =
            abi.encode(uint256(16), uint256(16), layers, colors, drawing);

        uint256 id = metadata.create(data);

        Property memory property = Property({
            creator: address(this),
            rule: IRule(address(0)),
            metadata: metadata,
            metadataId: id
        });
        copyright.setPropertyInfo(1, property);
    }
}
