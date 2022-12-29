// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {LengthMismatch, Unauthorized, UnsafeRecipient} from "../interfaces/Errors.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IERC1155} from "../interfaces/IERC1155.sol";
import {IERC1155MetadataURI} from "../interfaces/IERC1155MetadataURI.sol";
import {IERC1155Receiver} from "../interfaces/IERC1155Receiver.sol";
import {ERC165} from "./ERC165.sol";

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 is IERC1155, IERC1155MetadataURI, ERC165 {
    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    function uri(uint256 id) public view virtual returns (string memory);

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
            revert Unauthorized(msg.sender);
        }

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (
            to.code.length == 0
                ? to == address(0)
                : IERC1155Receiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) != IERC1155Receiver.onERC1155Received.selector
        ) {
            revert UnsafeRecipient(to);
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        if (ids.length != amounts.length) {
            revert LengthMismatch();
        }

        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
            revert Unauthorized(msg.sender);
        }

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (
            to.code.length == 0
                ? to == address(0)
                : IERC1155Receiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) != IERC1155Receiver.onERC1155BatchReceived.selector
        ) {
            revert UnsafeRecipient(to);
        }
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        if (owners.length != ids.length) {
            revert LengthMismatch();
        }

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        if (
            to.code.length == 0
                ? to == address(0)
                : IERC1155Receiver(to).onERC1155Received(
                    msg.sender,
                    address(0),
                    id,
                    amount,
                    data
                ) != IERC1155Receiver.onERC1155Received.selector
        ) {
            revert UnsafeRecipient(to);
        }
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        if (idsLength != amounts.length) {
            revert LengthMismatch();
        }

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        if (
            to.code.length == 0
                ? to == address(0)
                : IERC1155Receiver(to).onERC1155BatchReceived(
                    msg.sender,
                    address(0),
                    ids,
                    amounts,
                    data
                ) != IERC1155Receiver.onERC1155BatchReceived.selector
        ) {
            revert UnsafeRecipient(to);
        }
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        if (idsLength != amounts.length) {
            revert LengthMismatch();
        }

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}
