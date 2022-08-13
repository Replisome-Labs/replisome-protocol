// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "./IERC20.sol";
import {ICopyrightRenderer} from "./ICopyrightRenderer.sol";

interface IConfigurator {
    event TreaturyUpdated(address indexed vault);

    event FeeTokenUpdated(IERC20 indexed token);

    event CopyrightClaimFeeUpdated(uint256 amount);

    event CopyrightWaiveFeeUpdated(uint256 amount);

    event ArtworkCopyFeeUpdated(uint256 amount);

    event ArtworkBurnFeeUpdated(uint256 amount);

    event CopyrightRendererUpdated(ICopyrightRenderer indexed renderer);

    function treatury() external view returns (address vault);

    function feeToken() external view returns (IERC20 token);

    function copyrightClaimFee() external view returns (uint256 amount);

    function copyrightWaiveFee() external view returns (uint256 amount);

    function artworkCopyFee() external view returns (uint256 amount);

    function artworkBurnFee() external view returns (uint256 amount);

    function copyrightRenderer()
        external
        view
        returns (ICopyrightRenderer renderer);

    function setTreatury(address vault) external;

    function setFeeToken(IERC20 token) external;

    function setCopyrightClaimFee(uint256 amount) external;

    function setCopyrightWaiveFee(uint256 amount) external;

    function setArtworkCopyFee(uint256 amount) external;

    function setArtworkBurnFee(uint256 amount) external;

    function setCopyrightRenderer(ICopyrightRenderer renderer) external;
}
