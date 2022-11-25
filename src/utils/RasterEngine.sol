// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {FrameSizeMistatch, FrameSizeOverflow, FrameOutOfBoundary, ColorNotFound} from "../interfaces/Errors.sol";
import {Rotate, Flip} from "../interfaces/Structs.sol";

library RasterEngine {
    struct Palette {
        uint8 colorCount;
        mapping(uint8 => bytes4) colorOf;
        mapping(bytes4 => uint8) colorIndexOf;
    }

    function toBytes(Palette storage palette)
        public
        view
        returns (bytes memory raw)
    {
        uint8 count = palette.colorCount;
        raw = abi.encodePacked(raw, count);
        unchecked {
            for (uint8 i = 0; i < count; i++) {
                raw = abi.encodePacked(raw, palette.colorOf[i + 1]);
            }
        }
    }

    function getColorIndex(Palette storage palette, bytes4 color)
        public
        view
        returns (uint8 colorIndex)
    {
        colorIndex = palette.colorIndexOf[color];
    }

    function getColor(Palette storage palette, uint8 colorIndex)
        public
        view
        returns (bytes4 color)
    {
        color = palette.colorOf[colorIndex];
    }

    function getColors(Palette storage palette)
        public
        view
        returns (bytes4[] memory colors)
    {
        colors = new bytes4[](palette.colorCount);
        unchecked {
            for (uint8 i = 0; i < palette.colorCount; i++) {
                colors[i] = palette.colorOf[i + 1];
            }
        }
    }

    function addColor(Palette storage palette, bytes4 color) public {
        uint8 colorIndex = palette.colorIndexOf[color];
        if (colorIndex == uint8(0)) {
            colorIndex = ++((palette.colorCount));
            palette.colorOf[colorIndex] = color;
            palette.colorIndexOf[color] = colorIndex;
        }
    }

    function clearColors(Palette storage palette) public {
        unchecked {
            for (uint8 i = 1; i <= palette.colorCount; i++) {
                bytes4 c = palette.colorOf[i];
                delete palette.colorIndexOf[c];
                delete palette.colorOf[i];
            }
        }
        delete palette.colorCount;
    }

    struct Frame {
        uint256 width;
        uint256 height;
        bytes data;
    }

    function toBytes(Frame memory frame)
        internal
        pure
        returns (bytes memory raw)
    {
        raw = abi.encodePacked(frame.width, frame.height, frame.data);
    }

    function addFrame(Frame memory baseFrame, Frame memory layerFrame)
        internal
        pure
    {
        if (
            baseFrame.width != layerFrame.width ||
            baseFrame.height != layerFrame.height
        ) {
            revert FrameSizeMistatch();
        }
        unchecked {
            for (uint256 i = 0; i < layerFrame.data.length; i++) {
                bytes1 pixel = layerFrame.data[i];
                if (pixel == bytes1(0)) continue;
                baseFrame.data[i] = pixel;
            }
        }
    }

    function normalizeColors(
        Frame memory frame,
        Palette storage fromPalette,
        Palette storage toPalette
    ) internal view {
        unchecked {
            for (uint256 i = 0; i < frame.data.length; i++) {
                bytes1 pixel = frame.data[i];
                if (pixel == bytes1(0)) continue;
                bytes4 color = getColor(fromPalette, uint8(pixel));
                uint8 colorIndex = getColorIndex(toPalette, color);
                if (colorIndex == uint8(0)) {
                    revert ColorNotFound(color);
                }
                frame.data[i] = bytes1(colorIndex);
            }
        }
    }

    function transformFrame(
        Frame memory frame,
        Rotate rotate,
        Flip flip,
        uint256 translateX,
        uint256 translateY,
        uint256 baseWidth,
        uint256 baseHeight
    ) internal pure {
        rotateFrame(frame, rotate);
        flipFrame(frame, flip);
        translateFrame(frame, translateX, translateY, baseWidth, baseHeight);
    }

    function rotateFrame(Frame memory frame, Rotate rotate) internal pure {
        bytes memory newData = new bytes(frame.data.length);
        for (uint256 i = 0; i < frame.data.length; i++) {
            bytes1 pixel = frame.data[i];
            if (pixel == bytes1(0)) continue;

            uint256 x = i % frame.width;
            uint256 y = i / frame.height;

            if (rotate == Rotate.D90) {
                uint256 oldX = x;
                x = frame.height - y - 1;
                y = oldX;
            } else if (rotate == Rotate.D180) {
                x = frame.width - x - 1;
                y = frame.height - y - 1;
            } else if (rotate == Rotate.D270) {
                uint256 oldX = x;
                x = y;
                y = frame.width - oldX - 1;
            }

            uint256 pos = y * frame.width + x;
            newData[pos] = pixel;
        }
        frame.data = newData;
    }

    function flipFrame(Frame memory frame, Flip flip) internal pure {
        bytes memory newData = new bytes(frame.data.length);
        for (uint256 i = 0; i < frame.data.length; i++) {
            bytes1 pixel = frame.data[i];
            if (pixel == bytes1(0)) continue;

            uint256 x = i % frame.width;
            uint256 y = i / frame.height;

            if (flip == Flip.Horizontal) {
                x = frame.width - x - 1;
            } else if (flip == Flip.Vertical) {
                y = frame.height - y - 1;
            }

            uint256 pos = y * frame.width + x;
            newData[pos] = pixel;
        }
        frame.data = newData;
    }

    function translateFrame(
        Frame memory frame,
        uint256 translateX,
        uint256 translateY,
        uint256 baseWidth,
        uint256 baseHeight
    ) internal pure {
        if (
            frame.width + translateX > baseWidth ||
            frame.height + translateY > baseHeight
        ) {
            revert FrameOutOfBoundary();
        }

        scaleFrame(frame, baseWidth, baseHeight);

        bytes memory newData = new bytes(frame.data.length);
        for (uint256 i = 0; i < frame.data.length; i++) {
            bytes1 pixel = frame.data[i];
            if (pixel == bytes1(0)) continue;
            uint256 x = (i % frame.width) + translateX;
            uint256 y = i / frame.height + translateY;
            uint256 pos = y * frame.width + x;
            newData[pos] = pixel;
        }
        frame.data = newData;
    }

    function scaleFrame(
        Frame memory frame,
        uint256 toWidth,
        uint256 toHeight
    ) internal pure {
        if (frame.width > toWidth || frame.height > toHeight) {
            revert FrameSizeOverflow();
        }
        frame.width = toWidth;
        frame.height = toHeight;
    }
}
