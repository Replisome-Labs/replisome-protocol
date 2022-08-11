// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ICopyright} from "./interfaces/ICopyright.sol";
import {ERC721} from "./libraries/ERC721.sol";

contract Copyright is ICopyright, ERC721 {}
