// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IRuleset} from "./IRuleset.sol";

interface IRulesetFactory {
    /**
     * @dev Emits when creating a ruleset
     */
    event Created(address ruleset);

    /**
     * @dev create a ruleset
     * Emit a {Created} event
     */
    function create(bytes calldata data) external returns (IRuleset instance);
}
