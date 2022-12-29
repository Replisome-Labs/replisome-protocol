// SPDX-License-Identifier: MIT
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

    mapping(address => mapping(IRuleset => uint256)) public canApply;

    address public saleRoyaltyReceiver;
    uint256 public saleRoyaltyAmount;

    function getSaleRoyalty(uint256)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = saleRoyaltyReceiver;
        royaltyAmount = saleRoyaltyAmount;
    }

    address public copyRoyaltyReceiver;
    IERC20 public copyRoyaltyToken;
    uint256 public copyRoyaltyAmount;

    function getCopyRoyalty(uint256)
        external
        view
        returns (
            address receiver,
            IERC20 token,
            uint256 royaltyAmount
        )
    {
        receiver = copyRoyaltyReceiver;
        token = copyRoyaltyToken;
        royaltyAmount = copyRoyaltyAmount;
    }

    address public burnRoyaltyReceiver;
    IERC20 public burnRoyaltyToken;
    uint256 public burnRoyaltyAmount;

    function getBurnRoyalty(uint256)
        external
        view
        returns (
            address receiver,
            IERC20 token,
            uint256 royaltyAmount
        )
    {
        receiver = burnRoyaltyReceiver;
        token = burnRoyaltyToken;
        royaltyAmount = burnRoyaltyAmount;
    }

    address public utilizeRoyaltyReceiver;
    IERC20 public utilizeRoyaltyToken;
    uint256 public utilizeRoyaltyAmount;

    function getUtilizeRoyalty(uint256)
        external
        view
        returns (
            address receiver,
            IERC20 token,
            uint256 royaltyAmount
        )
    {
        receiver = utilizeRoyaltyReceiver;
        token = utilizeRoyaltyToken;
        royaltyAmount = utilizeRoyaltyAmount;
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
