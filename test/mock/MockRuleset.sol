// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IRuleset} from "../../src/interfaces/IRuleset.sol";
import {Action} from "../../src/interfaces/Structs.sol";
import {IERC20} from "../../src/interfaces/IERC20.sol";
import {IERC165} from "../../src/interfaces/IERC165.sol";
import {ERC165} from "../../src/libraries/ERC165.sol";

contract MockRuleset is IRuleset, ERC165 {
    bool public isUpgradable = true;

    mapping(address => uint256) public canTransfer;

    mapping(address => uint256) public canCopy;

    mapping(address => uint256) public canBurn;

    mapping(address => mapping(IRuleset => uint256)) public canUse;

    mapping(Action => address) public getRoyaltyReceiver;

    mapping(Action => IERC20) public getRoyaltyToken;

    mapping(Action => uint256) public royaltyPercantage;

    function getRoyaltyAmount(Action action, uint256 price)
        external
        view
        returns (uint256 amount)
    {
        amount = (price * royaltyPercantage[action]) / uint256(100);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IRuleset).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
