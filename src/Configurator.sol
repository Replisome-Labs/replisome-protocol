// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AlreadyPaused, YetPaused} from "./interfaces/Errors.sol";
import {IConfigurator, Action} from "./interfaces/IConfigurator.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {INFTRenderer} from "./interfaces/INFTRenderer.sol";
import {IFeeFormula} from "./interfaces/IFeeFormula.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";
import {Owned} from "./libraries/Owned.sol";

contract Configurator is Owned(msg.sender), IConfigurator {
    bool public paused;

    INFTRenderer public copyrightRenderer;

    address public treasury;

    IERC20 public feeToken;

    mapping(Action => IFeeFormula) public fees;

    function getFeeAmount(
        Action action,
        IMetadata metadata,
        uint256 metadataId,
        uint256 amount
    ) external view returns (uint256 price) {
        IFeeFormula feeFormula = fees[action];
        if (address(feeFormula) == address(0)) {
            price = uint256(0);
        } else {
            price = feeFormula.getPrice(metadata, metadataId, amount);
        }
    }

    function setFeeFormula(Action action, IFeeFormula feeFormula)
        external
        onlyOwner
    {
        fees[action] = feeFormula;
        emit FeeUpdated(action, feeFormula);
    }

    function setTreasury(address vault) external onlyOwner {
        treasury = vault;
        emit TreasuryUpdated(vault);
    }

    function setFeeToken(IERC20 token) external onlyOwner {
        feeToken = token;
        emit FeeTokenUpdated(token);
    }

    function setCopyrightRenderer(INFTRenderer renderer) external onlyOwner {
        copyrightRenderer = renderer;
        emit CopyrightRendererUpdated(renderer);
    }

    function pause() external onlyOwner {
        if (paused == true) {
            revert AlreadyPaused();
        }
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        if (paused == false) {
            revert YetPaused();
        }
        paused = false;
        emit Unpaused();
    }
}
