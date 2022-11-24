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
import {Layer, Rotate, Flip} from "../src/interfaces/Structs.sol";

contract CanvasTest is Test, ERC1155Receiver, ERC721Receiver {
    using stdStorage for StdStorage;

    uint256 public constant ZERO = uint256(0);

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
        metadata = new RasterMetadata(copyright);
        rule = new CC0Rule();

        metadataRegistry.register(metadata);

        artwork.setApprovalForAll(address(canvas), true);
    }

    function testCreate() public {
        Layer[] memory layers = new Layer[](0);
        bytes4[] memory colors = new bytes4[](1);
        colors[0] = hex"000000FF";

        bytes memory drawing = new bytes(256);
        for (uint256 i = 0; i < 256; i++) {
            if (i == 0 || i == 20 || i == 30) {
                drawing[i] = bytes1(uint8(1));
            } else {
                drawing[i] = bytes1(uint8(0));
            }
        }
        bytes memory data =
            abi.encode(uint256(16), uint256(16), layers, colors, drawing);

        canvas.create(1, rule, metadata, data);

        // emit log(artwork.uri(1));

        assertEq(copyright.balanceOf(address(this)), 1);
        assertEq(artwork.balanceOf(address(this), 1), 1);
    }
}
