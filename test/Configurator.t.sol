// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Configurator} from "../src/Configurator.sol";
import {Unauthorized} from "../src/interfaces/Errors.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {INFTRenderer} from "../src/interfaces/INFTRenderer.sol";

contract ConfiguratorTest is Test {
    event TreasuryUpdated(address indexed vault);

    event FeeTokenUpdated(IERC20 indexed token);

    event CopyrightRendererUpdated(INFTRenderer indexed renderer);

    Configurator public configurator;

    address public constant prankAddress = address(0);
    address public constant treasury = address(100);
    IERC20 public constant feeToken = IERC20(address(200));
    uint256 public constant copyrightClaimFee = uint256(300);
    uint256 public constant copyrightWaiveFee = uint256(400);
    uint256 public constant artworkCopyFee = uint256(500);
    uint256 public constant artworkBurnFee = uint256(600);
    INFTRenderer public constant copyrightRenderer = INFTRenderer(address(700));

    function setUp() public {
        configurator = new Configurator();
    }

    function testSetTreasury() public {
        vm.expectEmit(true, false, false, false);
        emit TreasuryUpdated(treasury);
        configurator.setTreasury(treasury);
        assertEq(configurator.treasury(), treasury);
    }

    function testSetTreasuryAsNotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(Unauthorized.selector, prankAddress)
        );
        vm.startPrank(prankAddress);
        configurator.setTreasury(treasury);
        vm.stopPrank();
    }

    function testSetFeeToken() public {
        vm.expectEmit(true, false, false, false);
        emit FeeTokenUpdated(feeToken);
        configurator.setFeeToken(feeToken);
        assertEq(address(configurator.feeToken()), address(feeToken));
    }

    function testSetFeeTokenAsNotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(Unauthorized.selector, prankAddress)
        );
        vm.startPrank(prankAddress);
        configurator.setFeeToken(feeToken);
        vm.stopPrank();
    }

    function testSetCopyrightRenderer() public {
        vm.expectEmit(true, false, false, false);
        emit CopyrightRendererUpdated(copyrightRenderer);
        configurator.setCopyrightRenderer(copyrightRenderer);
        assertEq(
            address(configurator.copyrightRenderer()),
            address(copyrightRenderer)
        );
    }

    function testSetCopyrightRendererAsNotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(Unauthorized.selector, prankAddress)
        );
        vm.startPrank(prankAddress);
        configurator.setCopyrightRenderer(copyrightRenderer);
        vm.stopPrank();
    }
}
