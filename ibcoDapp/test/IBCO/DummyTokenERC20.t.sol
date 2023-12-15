// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {DummyHegicTokenERC20} from "src/Treasury/DummyHegicTokenERC20.sol";

contract TestDummyTokenERC20 is Test {
    DummyHegicTokenERC20 htoken;
    address owner;
    address investor;
    uint256 constant initialSupply = 1200000000 * (10 ** 18);

    function setUp() public {
        owner = makeAddr("Queen");
        investor = makeAddr("Rabbit");

        vm.prank(owner);
        htoken = new DummyHegicTokenERC20();
    }

    function test_IsseuTokenReturnBalance_byOwner() public {
        vm.startPrank(owner);

        /// check initial supply value
        assertEq(htoken.balanceOf(address(owner)), initialSupply);

        vm.stopPrank();
    }

    function test_MIntTokenReturnBalance_byInvestor() public {
        uint256 dummyAmount = 1 * (10 ** 18);

        /// check has balance value
        vm.prank(investor);
        assertEq(htoken.balanceOf(address(investor)), 0);

        vm.prank(owner);
        /// mint to investor, amount
        htoken.mintTo(address(investor), dummyAmount);

        /// check has balance value
        vm.prank(investor);
        assertEq(htoken.balanceOf(address(investor)), dummyAmount);
    }
}
