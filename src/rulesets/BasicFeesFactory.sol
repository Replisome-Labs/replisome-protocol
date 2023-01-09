// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BasicFees} from "./BasicFees.sol";
import {LibClone} from "../libraries/LibClone.sol";
import {IERC20} from "../interfaces/IERC20.sol";

contract BasicFeesFactory {
    using LibClone for address;

    address public implementation;

    constructor() {
        implementation = address(
            new BasicFees(false, address(0), IERC20(address(0)), 0, 0, 0, 0)
        );
    }

    function create(bytes calldata data) external returns (address instance) {
        instance = implementation.clone(data);
    }
}
