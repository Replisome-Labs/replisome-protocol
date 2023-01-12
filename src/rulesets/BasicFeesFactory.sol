// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BasicFees} from "./BasicFees.sol";
import {LibClone} from "../libraries/LibClone.sol";
import {IRuleset} from "../interfaces/IRuleset.sol";
import {IRulesetFactory} from "../interfaces/IRulesetFactory.sol";
import {IERC20} from "../interfaces/IERC20.sol";

contract BasicFeesFactory is IRulesetFactory {
    using LibClone for address;

    address public implementation;

    constructor() {
        implementation = address(
            new BasicFees(false, address(0), IERC20(address(0)), 0, 0, 0, 0)
        );
    }

    function create(bytes calldata data) external returns (IRuleset ruleset) {
        address instance = implementation.clone(data);
        ruleset = IRuleset(instance);
        emit Created(instance);
    }
}
