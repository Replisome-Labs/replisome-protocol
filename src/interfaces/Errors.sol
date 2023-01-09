// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IRuleset} from "./IRuleset.sol";
import {IMetadata} from "./IMetadata.sol";
import {Layer} from "../RasterMetadata.sol";

// Common

error LengthMismatch(); // ff633a38

error NotContract(address target); // b5cf5b8f

error InvalidContract(address target); // ec016484

error FailedCall(address target, bytes data, bytes returndata); // 81a4deb2

error Reentrancy(); // ab143c06

error Unauthorized(address account); // 8e4a23d6

// Token

error AlreadyMinted(uint256 tokenId); // a593dbf8

error NotMinted(uint256 tokenId); // 9fe59932

error NotOwner(uint256 tokenId, address account); // b9c08761

error InvalidOwner(address account); // b20f76e3

error InvalidRecipient(address account); // 17858bbe

error UnsafeRecipient(address account); // 58c3bed4

error InsufficientAllowance(); // 13be252b

error PermitDeadlineExpired(); // 05787bdf

error InvalidSigner(address account); // bf18af43

// Copyright

error InvalidCreator(address account); // fec99a9d

error InvalidMetadata(IMetadata metadata); // dfc613a9

error InvalidRuleset(IRuleset ruleset); // 05288364

error NotUpgradableRuleset(IRuleset ruleset); // 9cb2735d

error ForbiddenToApply(uint256 tokenId); // 6e336b92

// Artwork

error ForbiddenToTransfer(uint256 tokenId); // 69afc2df

error ForbiddenToCopy(uint256 tokenId); // 78941072

error ForbiddenToBurn(uint256 tokenId); // baa5861f

// Metadata

error AlreadyRegisteredMetadata(IMetadata metadata); // 1f88e44e

error NotRegisteredMetadata(IMetadata metadata); // 594ca23f

error InexistenceMetadata(IMetadata metadata, uint256 metadataId); // f8a7ace8

error UnsupportedMetadata(IMetadata metadata); // 1c041959

error AlreadyCreated(uint256 metadataId); // f2de5dcb

error InvalidLayer(Layer layer); // 1dac55a7

error LayerNotExisted(Layer layer); // 2622b7b5

error LayerOutOfBoundary(Layer layer); // 10023977

error InvalidDrawing(bytes drawing); // f355dc56

// Other
error FrameSizeMistatch(); // 3725c9c6

error FrameSizeOverflow(); // 4584161c

error FrameOutOfBoundary(); // 580f4093

error ColorNotFound(bytes4 color); // 5597883e
