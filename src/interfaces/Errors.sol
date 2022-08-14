// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IRule} from "./IRule.sol";
import {IMetadata} from "./IMetadata.sol";
import {Layer} from "./Structs.sol";

// Common

error LengthMismatch();

error NotContract(address target);

error InvalidContract(address target);

error FailedCall(address target, bytes data, bytes returndata);

error Reentrancy();

error Unauthorized(address account);

error InsufficientFee();

// Token

error AlreadyMinted(uint256 tokenId);

error NotMinted(uint256 tokenId);

error NotOwner(uint256 tokenId, address account);

error InvalidOwner(address account);

error InvalidRecipient(address account);

error UnsafeRecipient(address account);

error InsufficientAllowance();

error PermitDeadlineExpired();

error InvalidSigner(address account);

// Copyright

error InvalidCreator(address account);

error InvalidRule(IRule rule);

error InvalidMetadata(IMetadata metadata);

error InvalidLayer(Layer layer);

// Artwork

error Untransferable();

error Uncopiable();

error Unburnable();

// Metadata

error AlreadyRegisteredMetadata(IMetadata metadata);

error NotRegisteredMetadata(IMetadata metadata);

error InexistenceMetadata(IMetadata metadata, uint256 metadataId);