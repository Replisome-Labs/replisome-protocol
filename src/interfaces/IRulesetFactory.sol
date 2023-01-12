// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IRuleset} from "./IRuleset.sol";

interface IRulesetFactory {
    event Created(address ruleset);

    function create(bytes calldata data) external returns (IRuleset instance);
}
