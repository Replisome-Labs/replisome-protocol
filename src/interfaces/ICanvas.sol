// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC165} from "./IERC165.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";
import {IERC1155Receiver} from "./IERC1155Receiver.sol";
import {IRule} from "./IRule.sol";
import {IMetadata} from "./IMetadata.sol";
import {Layer} from "./Structs.sol";

interface ICanvas is IERC165, IERC721Receiver, IERC1155Receiver {
    function artwork() external view returns (address target);

    function copyright() external view returns (address target);

    function configurator() external view returns (address target);

    function create(
        uint256 amount,
        IRule rule,
        IMetadata metadata,
        bytes calldata drawing
    ) external;

    function compose(
        uint256 amount,
        IRule rule,
        IMetadata metadata,
        Layer[] calldata layers,
        bytes calldata drawing
    ) external;

    function copy(uint256 tokenId, uint256 amount) external;

    function waive(uint256 tokenId) external;

    function burn(uint256 tokenId, uint256 amount) external;
}
