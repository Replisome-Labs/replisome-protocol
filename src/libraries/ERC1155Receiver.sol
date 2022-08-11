// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {IERC1155Receiver} from "../interfaces/IERC1155Receiver.sol";

// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
contract ERC1155Receiver is IERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}
