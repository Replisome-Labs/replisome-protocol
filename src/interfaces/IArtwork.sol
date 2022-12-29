// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IConfigurator} from "./IConfigurator.sol";
import {ICopyright} from "./ICopyright.sol";
import {IERC1155} from "./IERC1155.sol";
import {IERC1155MetadataURI} from "./IERC1155MetadataURI.sol";
import {IERC2981} from "./IERC2981.sol";
import {IERC20} from "./IERC20.sol";
import {Action} from "./Structs.sol";

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

    function configurator() external view returns (IConfigurator target);

    function copyright() external view returns (ICopyright target);

    function ownedBalanceOf(address account, uint256 tokenId)
        external
        view
        returns (uint256 amount);

    function usedBalanceOf(address account, uint256 tokenId)
        external
        view
        returns (uint256 amount);

    function canTransfer(address account, uint256 tokenId)
        external
        view
        returns (uint256 allowance);

    function canCopy(address account, uint256 tokenId)
        external
        view
        returns (uint256 allowance);

    function canBurn(address account, uint256 tokenId)
        external
        view
        returns (uint256 allowance);

    function resetTransferAllowance(address account, uint256 tokenId)
        external
        returns (uint256 allowance);

    function resetCopyAllowance(address account, uint256 tokenId)
        external
        returns (uint256 allowance);

    function resetBurnAllowance(address account, uint256 tokenId)
        external
        returns (uint256 allowance);

    function copy(
        address account,
        uint256 tokenId,
        uint256 amount
    ) external;

    function burn(
        address account,
        uint256 tokenId,
        uint256 amount
    ) external;
}
