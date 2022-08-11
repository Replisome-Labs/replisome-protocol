// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IArtwork} from "./interfaces/IArtwork.sol";
import {ERC1155} from "./libraries/ERC1155.sol";

contract Artwork is IArtwork, ERC1155 {}
