// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {FrameSizeMistatch, FrameSizeOverflow, FrameOutOfBoundary, ColorNotFound} from "../interfaces/Errors.sol";

enum Rotate {
    D0,
    D90,
    D180,
    D270
}

enum Flip {
    None,
    Horizontal,
    Vertical
}

struct Palette {
    uint8 colorCount;
    mapping(uint8 => bytes4) colorOf;
    mapping(bytes4 => uint8) colorIndexOf;
}

struct Frame {
    uint256 width;
    uint256 height;
    bytes data;
}

library RasterEngine {
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
        for (uint256 i = 0; i < layerFrame.data.length; ) {
            if (layerFrame.data[i] != bytes1(0)) {
                baseFrame.data[i] = layerFrame.data[i];
            }
            unchecked {
                ++i;
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
        for (uint256 i = 0; i < frame.data.length; ) {
            pixel = frame.data[i];
            if (pixel != bytes1(0)) {
                color = getColor(fromPalette, uint8(pixel));
                colorIndex = getColorIndex(toPalette, color);
                if (colorIndex == uint8(0)) {
                    revert ColorNotFound(color);
                }

                frame.data[i] = bytes1(colorIndex);
            }

            unchecked {
                ++i;
            }
        }
    }

    function getRawData(Frame memory frame, bytes4[] memory colors)
        internal
        pure
        returns (bytes memory raw)
    {
        raw = abi.encode(frame.width, frame.height, colors, frame.data);
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
        if (frame.width > baseWidth || frame.height > baseHeight) {
            revert FrameSizeOverflow();
        }
        if (
            frame.width + translateX > baseWidth ||
            frame.height + translateY > baseHeight
        ) {
            revert FrameOutOfBoundary();
        }

        bytes memory newData = new bytes(baseWidth * baseHeight);
        uint256 x;
        uint256 y;
        for (uint256 i = 0; i < frame.data.length; ) {
            if (frame.data[i] != bytes1(0)) {
                x = i % frame.width;
                y = i / frame.width;
                (x, y) = rotatePixel(x, y, frame.width, frame.height, rotate);
                (x, y) = flipPixel(x, y, frame.width, frame.height, flip);
                (x, y) = translatePixel(x, y, translateX, translateY);
                newData[y * baseWidth + x] = frame.data[i];
            }
            unchecked {
                ++i;
            }
        }
        frame.width = baseWidth;
        frame.height = baseHeight;
        frame.data = newData;
    }

    function rotatePixel(
        uint256 x,
        uint256 y,
        uint256 width,
        uint256 height,
        Rotate rotate
    ) internal pure returns (uint256 newX, uint256 newY) {
        if (rotate == Rotate.D0) {
            newX = x;
            newY = y;
        } else if (rotate == Rotate.D90) {
            newX = height - y - 1;
            newY = x;
        } else if (rotate == Rotate.D180) {
            newX = width - x - 1;
            newY = height - y - 1;
        } else if (rotate == Rotate.D270) {
            newX = y;
            newY = width - x - 1;
        }
    }

    function flipPixel(
        uint256 x,
        uint256 y,
        uint256 width,
        uint256 height,
        Flip flip
    ) internal pure returns (uint256 newX, uint256 newY) {
        if (flip == Flip.None) {
            newX = x;
            newY = y;
        } else if (flip == Flip.Horizontal) {
            newX = width - x - 1;
            newY = y;
        } else if (flip == Flip.Vertical) {
            newX = x;
            newY = height - y - 1;
        }
    }

    function translatePixel(
        uint256 x,
        uint256 y,
        uint256 translateX,
        uint256 translateY
    ) internal pure returns (uint256 newX, uint256 newY) {
        newX = x + translateX;
        newY = y + translateY;
    }
}
