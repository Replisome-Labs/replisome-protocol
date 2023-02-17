// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IConfigurator, Action} from "./IConfigurator.sol";
import {ICopyright} from "./ICopyright.sol";
import {IERC1155} from "./IERC1155.sol";
import {IERC1155MetadataURI} from "./IERC1155MetadataURI.sol";
import {IERC2981} from "./IERC2981.sol";
import {IERC20} from "./IERC20.sol";

interface IArtwork is IERC1155, IERC1155MetadataURI, IERC2981 {
    event RoyaltyTransfer(
        address indexed from,
        address indexed to,
        IERC20 token,
        uint256 value,
        Action indexed action
    );

    event Utilized(address indexed account, uint256[] ids, uint256[] values);

    event Unutilized(address indexed account, uint256[] ids, uint256[] values);

    /**
     * @dev Returns the address of configurator.
     */
    function configurator() external view returns (IConfigurator target);

    /**
     * @dev Returns the address of copyright.
     */
    function copyright() external view returns (ICopyright target);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     */
    function ownedBalanceOf(address account, uint256 tokenId)
        external
        view
        returns (uint256 amount);

    /**
     * @dev Returns the amount of tokens of token type `id` used by `account`.
     */
    function usedBalanceOf(address account, uint256 tokenId)
        external
        view
        returns (uint256 amount);

    /**
     * @dev Returns the amount of the `tokenId` token that can be transferd by `account`.
     */
    function canTransfer(address account, uint256 tokenId)
        external
        view
        returns (uint256 allowance);

    /**
     * @dev Returns the amount of the `tokenId` token that can be copied by `account`.
     */
    function canCopy(address account, uint256 tokenId)
        external
        view
        returns (uint256 allowance);

    /**
     * @dev Returns the amount of the `tokenId` token that can be burned by `account`.
     */
    function canBurn(address account, uint256 tokenId)
        external
        view
        returns (uint256 allowance);

    /**
     * @dev Reset the transfer permission for the `tokenId` token for `account`.
     */
    function resetTransferAllowance(address account, uint256 tokenId)
        external
        returns (uint256 allowance);

    /**
     * @dev Reset the copy permission for the `tokenId` token for `account`.
     */
    function resetCopyAllowance(address account, uint256 tokenId)
        external
        returns (uint256 allowance);

    /**
     * @dev Reset the burn permission for the `tokenId` token for `account`.
     */
    function resetBurnAllowance(address account, uint256 tokenId)
        external
        returns (uint256 allowance);

    /**
     * @dev Mint `tokenId` token.
     * Emits an {Utilized} event when some tokens are utilized to compose the `tokenId` token.
     */
    function copy(
        address account,
        uint256 tokenId,
        uint256 amount
    ) external;

    /**
     * @dev Burn `tokenId` token.
     * Emits an {Unutilized} event when some tokens are recycled at the moment that the `tokenId` token is burned.
     */
    function burn(
        address account,
        uint256 tokenId,
        uint256 amount
    ) external;
}
