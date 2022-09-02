// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Canvas} from "../src/Canvas.sol";
import {Configurator} from "../src/Configurator.sol";
import {MetadataRegistry} from "../src/MetadataRegistry.sol";
import {Copyright} from "../src/Copyright.sol";
import {Artwork} from "../src/Artwork.sol";
import {RasterMetadata} from "../src/RasterMetadata.sol";
import {CC0Rule} from "../src/rules/CC0Rule.sol";
import {ERC1155Receiver} from "../src/libraries/ERC1155Receiver.sol";
import {ERC721Receiver} from "../src/libraries/ERC721Receiver.sol";
import {Layer, TransformParam} from "../src/interfaces/Structs.sol";

contract CanvasTest is Test, ERC1155Receiver, ERC721Receiver {
    using stdStorage for StdStorage;

    Canvas public canvas;
    Configurator public configurator;
    MetadataRegistry public metadataRegistry;
    Copyright public copyright;
    Artwork public artwork;
    RasterMetadata public metadata;
    CC0Rule public rule;

    function setUp() public {
        configurator = new Configurator();
        metadataRegistry = new MetadataRegistry();
        copyright = new Copyright(configurator, metadataRegistry);
        artwork = new Artwork(configurator, copyright);
        canvas = new Canvas(configurator, copyright, artwork);
        metadata = new RasterMetadata(copyright, 16, 16, 16);
        rule = new CC0Rule();

        metadataRegistry.register(metadata);

        artwork.setApprovalForAll(address(canvas), true);
    }

    function testCreate() public {
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

        canvas.create(1, rule, metadata, drawings);

        // emit log(artwork.uri(1));

        assertEq(copyright.balanceOf(address(this)), 1);
        assertEq(artwork.balanceOf(address(this), 1), 1);
    }

    function testCompose() public {
        bytes memory drawings1 = abi.encodePacked(
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

        uint256 token1Id = canvas.create(2, rule, metadata, drawings1);

        Layer[] memory layers = new Layer[](1);
        layers[0] = Layer({
            tokenId: token1Id,
            transforms: new TransformParam[](0)
        });
        bytes memory drawings2 = abi.encodePacked(
            uint32(8),
            uint32(8),
            uint32(1),
            uint32(0),
            uint32(0),
            uint32(0),
            uint32(0),
            uint8(0),
            type(uint8).max,
            type(uint8).max,
            type(uint8).max
        );
        uint256 token2Id = canvas.compose(1, rule, metadata, layers, drawings2);

        assertEq(copyright.balanceOf(address(this)), 2);
        assertEq(artwork.balanceOf(address(this), token1Id), 1);
        assertEq(artwork.balanceOf(address(this), token2Id), 1);
    }
}
