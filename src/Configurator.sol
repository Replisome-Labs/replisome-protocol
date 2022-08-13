// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IConfigurator} from "./interfaces/IConfigurator.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {ICopyrightRenderer} from "./interfaces/ICopyrightRenderer.sol";
import {Owned} from "./libraries/Owned.sol";

contract Configurator is Owned(msg.sender), IConfigurator {
    address public treatury;

    IERC20 public feeToken;

    uint256 public copyrightClaimFee;

    uint256 public copyrightWaiveFee;

    uint256 public artworkCopyFee;

    uint256 public artworkBurnFee;

    ICopyrightRenderer public copyrightRenderer;

    function setTreatury(address vault) external onlyOwner {
        treatury = vault;
        emit TreaturyUpdated(vault);
    }

    function setFeeToken(IERC20 token) external onlyOwner {
        feeToken = token;
        emit FeeTokenUpdated(token);
    }

    function setCopyrightClaimFee(uint256 amount) external onlyOwner {
        copyrightClaimFee = amount;
        emit CopyrightClaimFeeUpdated(amount);
    }

    function setCopyrightWaiveFee(uint256 amount) external onlyOwner {
        copyrightWaiveFee = amount;
        emit CopyrightWaiveFeeUpdated(amount);
    }

    function setArtworkCopyFee(uint256 amount) external onlyOwner {
        artworkCopyFee = amount;
        emit ArtworkCopyFeeUpdated(amount);
    }

    function setArtworkBurnFee(uint256 amount) external onlyOwner {
        artworkBurnFee = amount;
        emit ArtworkBurnFeeUpdated(amount);
    }

    function setCopyrightRenderer(ICopyrightRenderer renderer)
        external
        onlyOwner
    {
        copyrightRenderer = renderer;
        emit CopyrightRendererUpdated(renderer);
    }
}
