// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library BoardLib {
    struct Board {
        uint8 colorCount;
        mapping(uint8 => bytes4) colorOf;
        mapping(bytes4 => uint8) colorIndexOf;
        bytes data;
    }

    function fromBytes(Board storage board, bytes calldata raw) public {
        uint8 count = uint8(raw[0]);
        unchecked {
            for (uint8 i = 0; i < count; i++) {
                bytes4 color = bytes4(raw[i * 4 + 1:i * 4 + 5]);
                board.colorOf[i + 1] = color;
                board.colorIndexOf[color] = i + 1;
            }
        }
        board.colorCount = count;
        board.data = raw[count * 4 + 1:];
    }

    function toBytes(Board storage board)
        public
        view
        returns (bytes memory raw)
    {
        uint8 count = board.colorCount;
        raw = abi.encodePacked(raw, count);
        unchecked {
            for (uint8 i = 0; i < count; i++) {
                raw = abi.encodePacked(raw, board.colorOf[i + 1]);
            }
        }
        raw = abi.encodePacked(raw, board.data);
    }

    function isEmpty(Board storage board) public view returns (bool checked) {
        checked = board.data.length == 0;
    }

    function getColors(Board storage board)
        public
        view
        returns (bytes4[] memory colors)
    {
        uint8 count = board.colorCount;
        colors = new bytes4[](count);
        unchecked {
            for (uint8 i = 0; i < count; i++) {
                colors[i] = board.colorOf[i + 1];
            }
        }
    }

    function fillColor(
        Board storage board,
        uint256 positionIndex,
        bytes4 color
    ) public {
        uint8 colorIndex = board.colorIndexOf[color];
        if (colorIndex == uint8(0)) {
            colorIndex = ++board.colorCount;
            board.colorOf[colorIndex] = color;
            board.colorIndexOf[color] = colorIndex;
        }
        board.data[positionIndex] = bytes1(colorIndex);
    }

    function clear(Board storage board) public {
        unchecked {
            for (uint8 i = 1; i <= board.colorCount; i++) {
                bytes4 c = board.colorOf[i];
                delete board.colorIndexOf[c];
                delete board.colorOf[i];
            }
        }
        delete board.colorCount;
        delete board.data;
    }
}
