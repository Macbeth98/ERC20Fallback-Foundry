// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ERC20Fallback} from "../src/ERC20Fallback.sol";

contract ERC20FallbackTest is Test {
    bytes4 private constant NAME_SELECTOR = bytes4(keccak256("name()"));
    bytes4 private constant SYMBOL_SELECTOR = bytes4(keccak256("symbol()"));
    bytes4 private constant DECIMALS_SELECTOR = bytes4(keccak256("decimals()"));

    bytes4 private constant TOTAL_SUPPLY_SELECTOR =
        bytes4(keccak256("totalSupply()"));
    bytes4 private constant BALANCE_OF_SELECTOR =
        bytes4(keccak256("balanceOf(address)"));
    bytes4 private constant ALLOWANCE_SELECTOR =
        bytes4(keccak256("allowance(address, address)"));

    bytes4 private constant TRANSFER_SELECTOR =
        bytes4(keccak256("transfer(address, uint256)"));
    bytes4 private constant TRANSFER_FROM_SELECTOR =
        bytes4(keccak256("transferFrom(address, address, uint256)"));
    bytes4 private constant APPROVE_SELECTOR =
        bytes4(keccak256("approve(address, uint256)"));

    ERC20Fallback public token;

    address private constant owner = address(0xdeadbeef);

    address private constant user1 = address(0x1);
    address private constant user2 = address(0x2);

    function setUp() public {
        vm.deal(owner, 1000000);
        vm.prank(owner);
        token = new ERC20Fallback();
    }

    function balanceOf(address user) internal returns (uint256) {
        bytes memory data = abi.encodeWithSelector(BALANCE_OF_SELECTOR, user);
        (bool success, bytes memory returnData) = address(token).call(data);
        assertEq(success, true, "balanceOf: should be success");
        return abi.decode(returnData, (uint256));
    }

    function allowance(address spender) internal returns (uint256) {
        bytes memory data = abi.encodeWithSelector(
            ALLOWANCE_SELECTOR,
            owner,
            spender
        );
        (bool success, bytes memory returnData) = address(token).call(data);
        assertEq(success, true, "should be success");
        return abi.decode(returnData, (uint256));
    }

    function approve(address spender, uint256 value) internal returns (bool) {
        bytes memory data = abi.encodeWithSelector(
            APPROVE_SELECTOR,
            spender,
            value
        );
        vm.prank(owner);
        (bool success, bytes memory returnData) = address(token).call(data);
        assertEq(success, true, "approve: should be success");
        assertEq(
            abi.decode(returnData, (bool)),
            true,
            "approve: should be true"
        );

        return true;
    }

    function testName() public {
        bytes memory data = abi.encodeWithSelector(NAME_SELECTOR);
        (bool success, bytes memory returnData) = address(token).call(data);
        assertEq(success, true, "name: should be success");
        assertEq(
            abi.decode(returnData, (string)),
            "ERC20Fallback",
            "name: should be ERC20Fallback"
        );
    }

    function testSymbol() public {
        bytes memory data = abi.encodeWithSelector(SYMBOL_SELECTOR);
        (bool success, bytes memory returnData) = address(token).call(data);
        assertEq(success, true, "symbol: should be success");
        assertEq(
            abi.decode(returnData, (string)),
            "ERC20FB",
            "symbol: should be ERC20FB"
        );
    }

    function testDecimals() public {
        bytes memory data = abi.encodeWithSelector(DECIMALS_SELECTOR);
        (bool success, bytes memory returnData) = address(token).call(data);
        assertEq(success, true, "decimals: should be success");
        assertEq(abi.decode(returnData, (uint8)), 0, "decimals: should be 0");
    }

    function testTotalSupply() public {
        bytes memory data = abi.encodeWithSelector(TOTAL_SUPPLY_SELECTOR);
        (bool success, bytes memory returnData) = address(token).call(data);
        assertEq(success, true, "totalSupply: should be success");
        assertEq(
            abi.decode(returnData, (uint256)),
            1000000,
            "totalSupply: should be 1000000"
        );
    }

    function testBalanceOf() public {
        uint256 balance = balanceOf(owner);
        assertEq(balance, 1000000, "owner should have 1000000");
    }

    function testTransfer() public {
        bytes memory data = abi.encodeWithSelector(
            TRANSFER_SELECTOR,
            user1,
            1000
        );
        vm.prank(owner);
        (bool success, bytes memory returnData) = address(token).call(data);
        assertEq(success, true, "transfer: should be success");
        assertEq(
            abi.decode(returnData, (bool)),
            true,
            "transfer: should be true"
        );
        assertEq(balanceOf(user1), 1000, "transfer: user1 should have 1000");
        assertEq(
            balanceOf(owner),
            999000,
            "transfer: owner should have 999000"
        );
    }

    function testAllowance() public {
        uint256 allowanceValue = allowance(user1);
        assertEq(allowanceValue, 0, "allowance: should be 0");
    }

    function testApprove() public {
        bool success = approve(user1, 1000);
        assertEq(success, true, "approve: should be true");
        assertEq(allowance(user1), 1000, "approve: should be 1000");
    }

    function testTransferFrom() public {
        approve(user1, 1000);
        bytes memory data = abi.encodeWithSelector(
            TRANSFER_FROM_SELECTOR,
            owner,
            user1,
            1000
        );
        vm.prank(user1);
        (bool success, bytes memory returnData) = address(token).call(data);
        assertEq(success, true, "transferFrom: should be success");
        assertEq(
            abi.decode(returnData, (bool)),
            true,
            "transferFrom: should be true"
        );
        assertEq(
            balanceOf(user1),
            1000,
            "transferFrom: user1 should have 1000"
        );
        assertEq(
            balanceOf(owner),
            999000,
            "transferFrom: owner should have 999000"
        );
        assertEq(allowance(user1), 0, "transferFrom: allowance should be 0");
    }

    function testTransferFromFail() public {
        approve(user1, 1000);
        bytes memory data = abi.encodeWithSelector(
            TRANSFER_FROM_SELECTOR,
            owner,
            user1,
            1001
        );
        vm.prank(user1);
        vm.expectRevert();
        (bool success, ) = address(token).call(data);
        assertEq(success, true, "transferFrom: call Should be success");
        assertEq(balanceOf(user1), 0, "transferFrom: user1 should have 0");
        assertEq(
            balanceOf(owner),
            1000000,
            "transferFrom: owner should have 1000000"
        );
        assertEq(
            allowance(user1),
            1000,
            "transferFrom: allowance should be 1000"
        );
    }

    function testFallbackShouldRevert() public {
        vm.expectRevert();
        (bool success, ) = address(token).call("");
        assertEq(success, true, "fallback: call Should be success");
    }
}
