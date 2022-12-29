// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Artwork} from "../src/Artwork.sol";
import {Configurator} from "../src/Configurator.sol";
import {ConstantFeeFormula} from "../src/fees/ConstantFeeFormula.sol";
import {ForbiddenToCopy, ForbiddenToBurn} from "../src/interfaces/Errors.sol";
import {Action} from "../src/interfaces/Structs.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IFeeFormula} from "../src/interfaces/IFeeFormula.sol";
import {ERC20} from "../src/libraries/ERC20.sol";
import {ERC1155Receiver} from "../src/libraries/ERC1155Receiver.sol";
import {MockCopyright} from "./mock/MockCopyright.sol";
import {MockRuleset} from "./mock/MockRuleset.sol";

contract ArtworkTest is Test, ERC1155Receiver {
    using stdStorage for StdStorage;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    Artwork public artwork;
    Configurator public configurator;
    MockCopyright public mockCopyright;
    MockRuleset public mockRuleset;

    address public constant prankAddress = address(0);
    address public constant treatury = address(100);
    ERC20 public feeToken;
    IFeeFormula public feeFormula;
    ERC20 public royaltyToken;
    address public constant royaltyReceiver = address(400);
    uint256 public constant royaltyAmount = uint256(500);

    function setUp() public {
        ERC20 token = new ERC20("Test Token", "TST", 18);
        feeToken = token;
        royaltyToken = token;

        feeFormula = new ConstantFeeFormula(100);

        configurator = new Configurator();
        mockCopyright = new MockCopyright();
        mockRuleset = new MockRuleset();
        artwork = new Artwork(configurator, mockCopyright);

        mockStdStore();
    }

    function mockStdStore() public {
        stdstore
            .target(address(feeToken))
            .sig(feeToken.balanceOf.selector)
            .with_key(address(this))
            .checked_write(1000000000000000000);

        stdstore
            .target(address(configurator))
            .sig(configurator.treatury.selector)
            .checked_write(treatury);

        stdstore
            .target(address(configurator))
            .sig(configurator.feeToken.selector)
            .checked_write(address(feeToken));

        stdstore
            .target(address(configurator))
            .sig(configurator.fees.selector)
            .with_key(uint256(Action.ArtworkCopy))
            .checked_write(address(feeFormula));

        stdstore
            .target(address(configurator))
            .sig(configurator.fees.selector)
            .with_key(uint256(Action.ArtworkBurn))
            .checked_write(address(feeFormula));
    }

    function testCopy() public {
        stdstore
            .target(address(mockRuleset))
            .sig(mockRuleset.canCopy.selector)
            .with_key(address(this))
            .checked_write(type(uint256).max);

        stdstore
            .target(address(mockCopyright))
            .sig(mockCopyright.rulesetOf.selector)
            .with_key(1)
            .checked_write(address(mockRuleset));

        feeToken.approve(address(artwork), type(uint256).max);

        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0), address(this), 1, 1);

        artwork.copy(address(this), 1, 1);
    }

    function testCopyUnCopiable() public {
        stdstore
            .target(address(mockRuleset))
            .sig(mockRuleset.canCopy.selector)
            .with_key(address(this))
            .checked_write(type(uint256).min);

        stdstore
            .target(address(mockCopyright))
            .sig(mockCopyright.rulesetOf.selector)
            .with_key(1)
            .checked_write(address(mockRuleset));

        feeToken.approve(address(artwork), type(uint256).max);

        vm.expectRevert(
            abi.encodeWithSelector(ForbiddenToCopy.selector, uint256(1))
        );

        artwork.copy(address(this), 1, 1);
    }

    function testBurn() public {
        stdstore
            .target(address(mockRuleset))
            .sig(mockRuleset.canBurn.selector)
            .with_key(address(this))
            .checked_write(type(uint256).max);

        stdstore
            .target(address(mockCopyright))
            .sig(mockCopyright.rulesetOf.selector)
            .with_key(1)
            .checked_write(address(mockRuleset));

        stdstore
            .target(address(artwork))
            .sig(artwork.balanceOf.selector)
            .with_key(address(this))
            .with_key(1)
            .checked_write(1);

        stdstore
            .target(address(artwork))
            .sig(artwork.ownedBalanceOf.selector)
            .with_key(address(this))
            .with_key(1)
            .checked_write(1);

        feeToken.approve(address(artwork), type(uint256).max);

        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(this), address(0), 1, 1);

        artwork.burn(address(this), 1, 1);
    }

    function testBurnUnburnable() public {
        stdstore
            .target(address(mockRuleset))
            .sig(mockRuleset.canBurn.selector)
            .with_key(address(this))
            .checked_write(type(uint256).min);

        stdstore
            .target(address(mockCopyright))
            .sig(mockCopyright.rulesetOf.selector)
            .with_key(1)
            .checked_write(address(mockRuleset));

        stdstore
            .target(address(artwork))
            .sig(artwork.balanceOf.selector)
            .with_key(address(this))
            .with_key(1)
            .checked_write(1);

        stdstore
            .target(address(artwork))
            .sig(artwork.ownedBalanceOf.selector)
            .with_key(address(this))
            .with_key(1)
            .checked_write(1);

        feeToken.approve(address(artwork), type(uint256).max);

        vm.expectRevert(
            abi.encodeWithSelector(ForbiddenToBurn.selector, uint256(1))
        );

        artwork.burn(address(this), 1, 1);
    }
}
