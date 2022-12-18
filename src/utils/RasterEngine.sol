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
        if (palette.colorIndexOf[color] == uint8(0)) {
            uint8 colorCount = palette.colorCount;
            uint8 nextColorIndex;
            bytes4 currentColor;
            for (uint8 i = colorCount; i >= 0; ) {
                nextColorIndex = i + 1;
                currentColor = palette.colorOf[i];
                if (uint32(currentColor) < uint32(color)) {
                    palette.colorOf[nextColorIndex] = color;
                    palette.colorIndexOf[color] = nextColorIndex;
                    break;
                } else {
                    palette.colorOf[nextColorIndex] = currentColor;
                    palette.colorIndexOf[currentColor] = nextColorIndex;
                }
                unchecked {
                    --i;
                }
            }

            ++palette.colorCount;
        }
    }

    function clearColors(Palette storage palette) public {
        bytes4 color;
        for (uint8 i = 1; i <= palette.colorCount; ) {
            color = palette.colorOf[i];
            delete palette.colorIndexOf[color];
            delete palette.colorOf[i];
            unchecked {
                ++i;
            }
        }
        delete palette.colorCount;
    }

    struct Frame {
        uint256 width;
        uint256 height;
        bytes data;
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
        bytes1 pixel;
        unchecked {
            for (uint256 i = 0; i < layerFrame.data.length; i++) {
                pixel = layerFrame.data[i];
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
        bytes1 pixel;
        bytes4 color;
        uint8 colorIndex;
        unchecked {
            for (uint256 i = 0; i < frame.data.length; i++) {
                pixel = frame.data[i];
                if (pixel == bytes1(0)) continue;

                color = getColor(fromPalette, uint8(pixel));
                colorIndex = getColorIndex(toPalette, color);
                if (colorIndex == uint8(0)) {
                    revert ColorNotFound(color);
                }

                frame.data[i] = bytes1(colorIndex);
            }
        }
    }

    function getRawData(Frame memory frame, bytes4[] memory colors)
        internal
        pure
        returns (bytes memory raw)
    {
        raw = abi.encodePacked(frame.width, frame.height, colors, frame.data);
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
        if (rotate != Rotate.D0) {
            rotateFrame(frame, rotate);
        }
        if (flip != Flip.None) {
            flipFrame(frame, flip);
        }
        if (translateX != uint256(0) || translateY != uint256(0)) {
            translateFrame(
                frame,
                translateX,
                translateY,
                baseWidth,
                baseHeight
            );
        }
    }

    function rotateFrame(Frame memory frame, Rotate rotate) internal pure {
        bytes memory newData = new bytes(frame.data.length);
        bytes1 pixel;
        uint256 x;
        uint256 y;
        uint256 pos;
        uint256 temp;
        unchecked {
            for (uint256 i = 0; i < frame.data.length; i++) {
                pixel = frame.data[i];
                if (pixel == bytes1(0)) continue;

                x = i % frame.width;
                y = i / frame.height;

                if (rotate == Rotate.D90) {
                    temp = x;
                    x = frame.height - y - 1;
                    y = temp;
                } else if (rotate == Rotate.D180) {
                    x = frame.width - x - 1;
                    y = frame.height - y - 1;
                } else if (rotate == Rotate.D270) {
                    temp = x;
                    x = y;
                    y = frame.width - temp - 1;
                }

                pos = y * frame.width + x;
                newData[pos] = pixel;
            }
        }
        frame.data = newData;
    }

    function flipFrame(Frame memory frame, Flip flip) internal pure {
        bytes memory newData = new bytes(frame.data.length);
        bytes1 pixel;
        uint256 x;
        uint256 y;
        uint256 pos;
        unchecked {
            for (uint256 i = 0; i < frame.data.length; i++) {
                pixel = frame.data[i];
                if (pixel == bytes1(0)) continue;

                x = i % frame.width;
                y = i / frame.height;

                if (flip == Flip.Horizontal) {
                    x = frame.width - x - 1;
                } else if (flip == Flip.Vertical) {
                    y = frame.height - y - 1;
                }

                pos = y * frame.width + x;
                newData[pos] = pixel;
            }
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

        bytes memory newData = new bytes(baseWidth * baseHeight);
        bytes1 pixel;
        uint256 x;
        uint256 y;
        uint256 pos;
        unchecked {
            for (uint256 i = 0; i < frame.data.length; i++) {
                pixel = frame.data[i];
                if (pixel == bytes1(0)) continue;

                x = (i % frame.width) + translateX;
                y = i / frame.height + translateY;
                pos = y * baseWidth + x;
                newData[pos] = pixel;
            }
        }
        frame.data = newData;

        scaleFrame(frame, baseWidth, baseHeight);
    }

    function scaleFrame(
        Frame memory frame,
        uint256 width,
        uint256 height
    ) internal pure {
        if (frame.width > width || frame.height > height) {
            revert FrameSizeOverflow();
        }
        frame.width = width;
        frame.height = height;
    }
}
