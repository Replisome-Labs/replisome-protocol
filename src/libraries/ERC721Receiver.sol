// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {IERC721Receiver} from "../interfaces/IERC721Receiver.sol";

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
contract ERC721Receiver is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
