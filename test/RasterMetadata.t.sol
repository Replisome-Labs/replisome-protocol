// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {RasterMetadata} from "../src/RasterMetadata.sol";
import {Property, Layer, Rotate, Flip} from "../src/interfaces/Structs.sol";
import {IRuleset} from "../src/interfaces/IRuleset.sol";
import {MockCopyright} from "./mock/MockCopyright.sol";
import {MockRuleset} from "./mock/MockRuleset.sol";

contract RasterMetadataTest is Test {
    using stdStorage for StdStorage;

    event Created(uint256 indexed metadataId, bytes rawData);

    MockCopyright public mockCopyright;
    MockRuleset public mockRuleset;
    RasterMetadata public metadata;

    function setUp() public {
        mockCopyright = new MockCopyright();
        mockRuleset = new MockRuleset();
        metadata = new RasterMetadata(mockCopyright);
    }

    function testCreatWithoutLayers() public {
        Layer[] memory layers = new Layer[](0);
        bytes4[] memory colors = new bytes4[](1);
        colors[0] = hex"000000FF";

        bytes memory drawing = new bytes(256);
        for (uint256 i = 0; i < 256; i++) {
            drawing[i] = bytes1(uint8(1));
        }
        bytes memory data = abi.encode(
            uint256(16),
            uint256(16),
            layers,
            colors,
            drawing
        );

        vm.expectEmit(true, false, false, false);
        emit Created(1, data);

        uint256 id = metadata.create(data);

        // emit log_bytes(metadata.generateRawData(id));
        emit log(metadata.generateHTML(id));
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
        bytes memory data = abi.encode(
            uint256(16),
            uint256(16),
            layers,
            colors,
            drawing
        );

        vm.expectEmit(true, false, false, false);
        emit Created(2, data);

        uint256 id = metadata.create(data);

        emit log_bytes(metadata.generateRawData(id));
        // emit log(metadata.generateHTML(id));
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
        bytes memory data = abi.encode(
            uint256(16),
            uint256(16),
            layers,
            colors,
            drawing
        );

        uint256 id = metadata.create(data);

        stdstore
            .target(address(mockCopyright))
            .sig(mockCopyright.creatorOf.selector)
            .with_key(uint256(1))
            .checked_write(address(this));

        stdstore
            .target(address(mockCopyright))
            .sig(mockCopyright.rulesetOf.selector)
            .with_key(uint256(1))
            .checked_write(address(mockRuleset));

        stdstore
            .target(address(mockCopyright))
            .sig(mockCopyright._metadataContractOf.selector)
            .with_key(uint256(1))
            .checked_write(address(metadata));

        stdstore
            .target(address(mockCopyright))
            .sig(mockCopyright._metadataIdOf.selector)
            .with_key(uint256(1))
            .checked_write(id);
    }
}
