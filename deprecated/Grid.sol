// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Grid {
    struct Point {
        uint256 x;
        uint256 y;
    }

    function equalPoints(Point memory pointA, Point memory pointB)
        public
        pure
        returns (bool checked)
    {
        checked = pointA.x == pointB.x && pointA.y == pointB.y;
    }

    struct Board {
        Point[] points;
        mapping(uint256 => mapping(uint256 => bytes32)) pointValues;
    }

    function isEmpty(Board storage board) public view returns (bool checked) {
        checked = board.points.length == 0;
    }

    function at(Board storage board, Point memory point)
        public
        view
        returns (bytes32 value)
    {
        value = board.pointValues[point.x][point.y];
    }

    function exist(Board storage board, Point memory point)
        public
        view
        returns (bool checked)
    {
        checked = at(board, point) != bytes32(0);
    }

    function getValues(Board storage board)
        public
        view
        returns (bytes32[] memory values)
    {
        uint256 len = board.points.length;
        values = new bytes32[](len);
        unchecked {
            for (uint256 i = 0; i < len; i++) {
                values[i] = at(board, board.points[i]);
            }
        }
    }

    function insert(
        Board storage board,
        Point memory point,
        bytes32 value
    ) public {
        if (value == bytes32(0)) {
            remove(board, point);
            return;
        }

        if (!exist(board, point)) {
            board.points.push(point);
        }
        board.pointValues[point.x][point.y] = value;
    }

    function remove(Board storage board, Point memory point) public {
        uint256 len = board.points.length;
        if (len == 0) return;
        for (uint256 i = 0; i < len; i++) {
            if (equalPoints(board.points[i], point)) {
                board.points[i] = board.points[len - 1];
                break;
            }
        }
        delete board.pointValues[point.x][point.y];
        board.points.pop();
    }

    function clear(Board storage board) public {
        uint256 len = board.points.length;
        for (uint256 i = len - 1; i >= 0; i--) {
            Point memory point = board.points[i];
            delete board.pointValues[point.x][point.y];
            board.points.pop();
        }
    }
}
