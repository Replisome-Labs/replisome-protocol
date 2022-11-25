// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Action} from "./Structs.sol";
import {IERC20} from "./IERC20.sol";
import {ICopyrightRenderer} from "./ICopyrightRenderer.sol";
import {IFeeFormula} from "./IFeeFormula.sol";

interface IConfigurator {
    event TreaturyUpdated(address indexed vault);

    event FeeTokenUpdated(IERC20 indexed token);

    event FeeUpdated(Action indexed action, IFeeFormula feeFormula);

    event CopyrightRendererUpdated(ICopyrightRenderer indexed renderer);

    function treatury() external view returns (address vault);

    function setTreatury(address vault) external;

    function feeToken() external view returns (IERC20 token);

    function setFeeToken(IERC20 token) external;

    function getFeeAmount(
        Action action,
        uint256 tokenId,
        uint256 amount
    ) external view returns (uint256 price);

    function getFeeAmount(
        Action action,
        bytes calldata tokenData,
        uint256 amount
    ) external view returns (uint256 price);

    function setFeeFormula(Action action, IFeeFormula feeFormula) external;

    function copyrightRenderer()
        external
        view
        returns (ICopyrightRenderer renderer);

    function setCopyrightRenderer(ICopyrightRenderer renderer) external;
}
