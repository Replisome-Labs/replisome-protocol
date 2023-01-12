// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Canvas} from "../src/Canvas.sol";
import {Configurator} from "../src/Configurator.sol";
import {MetadataRegistry} from "../src/MetadataRegistry.sol";
import {Copyright} from "../src/Copyright.sol";
import {Artwork} from "../src/Artwork.sol";
import {RasterMetadata, Layer} from "../src/RasterMetadata.sol";
import {Rotate, Flip} from "../src/utils/RasterEngine.sol";
import {CC0} from "../src/rulesets/CC0.sol";
import {ERC1155Receiver} from "../src/libraries/ERC1155Receiver.sol";
import {ERC721Receiver} from "../src/libraries/ERC721Receiver.sol";

contract CanvasTest is Test, ERC1155Receiver, ERC721Receiver {
    using stdStorage for StdStorage;

    uint256 public constant ZERO = uint256(0);

    Canvas public canvas;
    Configurator public configurator;
    MetadataRegistry public metadataRegistry;
    Copyright public copyright;
    Artwork public artwork;
    RasterMetadata public metadata;
    CC0 public ruleset;

    function setUp() public {
        configurator = new Configurator();
        metadataRegistry = new MetadataRegistry();
        copyright = new Copyright(configurator, metadataRegistry);
        artwork = new Artwork(configurator, copyright);
        canvas = new Canvas(configurator, copyright, artwork);
        metadata = new RasterMetadata(copyright);
        ruleset = new CC0();

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
        bytes memory data = abi.encode(
            uint256(16),
            uint256(16),
            layers,
            colors,
            drawing
        );

        canvas.createArtwork(1, ruleset, metadata, data);

        assertEq(copyright.balanceOf(address(this)), 1);
        assertEq(artwork.balanceOf(address(this), 1), 1);
    }
}
