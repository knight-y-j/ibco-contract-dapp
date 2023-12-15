// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {InitialBondingCurve, EventInitialBondingCurve, ErrorInitialBondingCurve} from "src/IBCO/InitialBondingCurve.sol";
import {DummyTokenERC20} from "src/IBCO/DummyTokenERC20.sol";

contract TestIBCO is
    Test,
    EventInitialBondingCurve,
    ErrorInitialBondingCurve
{
    DummyTokenERC20 dht;
    InitialBondingCurve hibco;
    uint256 constant initialSupply = 200_000_000 * (10 ** 18);
    uint256 amount = 753001000 * (10 ** 18);
    address owner; // contract owner
    address investorA; // contract player 1st
    address investorB; // contract player 2nd
    address investorC; // contract player 3rd
    address investorD; // contract player 4th
    address investorE; // contract player 5th
    address investorF; // contract player 6th
    address investorG; // contract player 7th
    uint256 wallet;
    uint256 timestamp; // https://www.timestamp-converter.com/

    function setUp() public {
        /// setting actor address
        owner = makeAddr("Queen");
        investorA = makeAddr("King");
        investorB = makeAddr("Rabbit");
        investorC = makeAddr("Knight");
        investorD = makeAddr("Alice");
        investorE = makeAddr("Jabawaqe");
        investorF = makeAddr("HamptyDumpty");
        investorG = makeAddr("Ace");

        /// setting wallet
        wallet = 150 ether;
        vm.deal(owner, wallet);
        vm.deal(investorA, wallet);
        vm.deal(investorB, wallet);
        vm.deal(investorC, wallet);
        vm.deal(investorD, wallet);
        vm.deal(investorE, wallet);
        vm.deal(investorF, wallet);
        vm.deal(investorG, wallet);

        /// deploy dummy Hegic ERC20 token contract
        vm.startPrank(owner);
        dht = new DummyTokenERC20();

        /// deploy contract
        hibco = new InitialBondingCurve(address(dht));

        /// mintTo IBCO contract
        dht.mintTo(address(hibco), amount);
        vm.stopPrank();
    }

    function test_Success_HegicInitialBondingCurveToReceive_byOwner() public {
        /// check is send
        bool isSendETH;
        /// payable amount
        uint256 _amount = 0.01 ether;
        /// timestamp value
        timestamp = 1700967650; // 2023-11-26-12:00(JST)

        /// start
        vm.startPrank(owner); // by contract owner
        vm.warp(timestamp);

        vm.expectEmit(true, true, false, false);
        emit ReceivedEvent(address(owner), _amount);

        /// send eth to contract
        (isSendETH, ) = address(hibco).call{value: _amount}("");
        // payable(address(hibco)).transfer(_amount); // transfer method

        /// check is send ETH
        assertTrue(isSendETH);

        /// end
        vm.stopPrank();
        /// check balance
        assertEq(_amount, address(hibco).balance);
    }

    function test_Success_HegicInitialBondingCurve_Receive_byInvestor() public {
        /// payable amount
        uint256 _amount = 0.01 ether;
        /// timestamp value
        timestamp = 1700967650; // 2023-11-26-12:00(JST)

        /// start
        vm.startPrank(investorA); // by investor
        vm.warp(timestamp);

        vm.expectEmit(true, true, false, false);
        emit ReceivedEvent(address(investorA), _amount);

        /// send eth to contract
        (bool isSendETH, ) = address(hibco).call{value: _amount}("");
        // payable(address(hibco)).transfer(_amount); // transfer method

        /// check is send ETH
        assertTrue(isSendETH);

        /// end
        vm.stopPrank();
        /// check balance
        assertEq(_amount, address(hibco).balance);
    }

    function test_Fail_HegicInitialBondingCurveToReceive_OfferingHasNotStartedYet()
        public
    {
        /// payable amount
        uint256 _amount = 0.01 ether;
        /// timestamp value
        timestamp = 1700964050; // 2023-11-26-11:00(JST)

        /// start
        vm.startPrank(owner); // by contract owner
        vm.warp(timestamp);

        vm.expectRevert(
            abi.encodeWithSelector(
                OfferingHasNotStartedYet.selector,
                address(owner),
                timestamp
            )
        );

        /// send eth to contract
        (bool isSendETH, ) = address(hibco).call{value: _amount}("");
        // MEMO: payable(address(hibco)).transfer(_amount); // transfer method

        /// check is send ETH
        assertTrue(isSendETH); // Note: bug

        /// end
        vm.stopPrank();
        /// check balance
        assertNotEq(_amount, address(hibco).balance);
    }

    function test_Fail_HegicInitialBondingCurveToReceive_OfferingHasAlreadyEnded()
        public
    {
        /// payable amount
        uint256 _amount = 0.01 ether;
        /// timestamp value
        timestamp = 1701226850; // 2023-11-29-12:00(JST)

        /// start
        vm.startPrank(owner); // by contract owner
        vm.warp(timestamp);

        vm.expectRevert(
            abi.encodeWithSelector(
                OfferingHasAlreadyEnded.selector,
                address(owner),
                timestamp
            )
        );

        /// send eth to contract
        (bool isSendETH, ) = address(hibco).call{value: _amount}("");
        // MEMO: payable(address(hibco)).transfer(_amount); // transfer method
        /// check is send ETH
        assertTrue(isSendETH); // Note: bug

        /// end
        vm.stopPrank();
        /// check balance
        assertNotEq(_amount, address(hibco).balance);
    }

    function test_Success_HegicInitialBondingCurve_claim_byInvestor() public {
        /// check is send
        bool isSendETH;
        /// provided amount
        uint256 _amount = 100 ether;
        uint256 dummyTotalAmount = 90360300000000000000000000;
        /// timestamp value
        timestamp = 1700967650; // 2023-11-26-12:00(JST)

        /// start
        vm.warp(timestamp);
        vm.startPrank(investorA); // by contract investor

        vm.expectEmit(true, true, false, false);
        emit ReceivedEvent(address(investorA), _amount);

        /// send eth to contract
        (isSendETH, ) = address(hibco).call{value: _amount}("");

        /// check is send ETH
        assertTrue(isSendETH);
        vm.stopPrank();

        /// start
        vm.startPrank(investorB); // by contract investor

        vm.expectEmit(true, true, false, false);
        emit ReceivedEvent(address(investorB), _amount);

        /// send eth to contract
        (isSendETH, ) = address(hibco).call{value: _amount}("");

        /// check is send ETH
        assertTrue(isSendETH);
        vm.stopPrank();
        vm.startPrank(investorC); // by contract investor

        vm.expectEmit(true, true, false, false);
        emit ReceivedEvent(address(investorC), _amount);

        /// send eth to contract
        (isSendETH, ) = address(hibco).call{value: _amount}("");

        /// check is send ETH
        assertTrue(isSendETH);
        vm.stopPrank();
        vm.startPrank(investorD); // by contract investor

        vm.expectEmit(true, true, false, false);
        emit ReceivedEvent(address(investorD), _amount);

        /// send eth to contract
        (isSendETH, ) = address(hibco).call{value: _amount}("");

        /// check is send ETH
        assertTrue(isSendETH);
        vm.stopPrank();
        vm.startPrank(investorE); // by contract investor

        vm.expectEmit(true, true, false, false);
        emit ReceivedEvent(address(investorE), _amount);

        /// send eth to contract
        (isSendETH, ) = address(hibco).call{value: _amount}("");

        /// check is send ETH
        assertTrue(isSendETH);
        vm.stopPrank();
        vm.startPrank(investorF); // by contract investor

        vm.expectEmit(true, true, false, false);
        emit ReceivedEvent(address(investorF), _amount);

        /// send eth to contract
        (isSendETH, ) = address(hibco).call{value: _amount}("");

        /// check is send ETH
        assertTrue(isSendETH);
        vm.stopPrank();
        vm.startPrank(investorG); // by contract investor

        vm.expectEmit(true, true, false, false);
        emit ReceivedEvent(address(investorG), _amount);

        /// send eth to contract
        (isSendETH, ) = address(hibco).call{value: _amount}("");
        // 0x0BD4Ee503F62EA5aAEC0601Cf92dC00A825B51bB
        /// check is send ETH
        assertTrue(isSendETH);
        vm.stopPrank();

        /// start claim
        vm.startPrank(investorA);
        timestamp = 1701399650; // 2023-12-01-12:00(JST)
        vm.warp(timestamp);

        // vm.expectEmit(true, true, true, false);
        // emit ClaimedEvent(address(investorA), _amount, dummyTotalAmount);

        /// call claim
        hibco.claim();

        /// end
        vm.stopPrank();
    }

    function test_NG_HegicInitialBondingCurve_Claim_OfferingMustBeCompleted()
        public
    {
        /// timestamp value
        timestamp = 1700967650; // 2023-11-26-12:00(JST)

        /// start
        vm.startPrank(investorA); // by investor
        vm.warp(timestamp);
        vm.expectRevert(
            abi.encodeWithSelector(
                OfferingMustBeCompleted.selector,
                address(investorA),
                timestamp
            )
        );
        /// call claim
        hibco.claim();
        /// end
        vm.stopPrank();
    }

    function test_Fail_HegicInitialBondingCurve_Claim_ProvidedAmountIsEmpty()
        public
    {
        /// provided amount
        uint256 _amount = 0;
        /// timestamp value
        timestamp = 1701399650; // 2023-12-01-12:00(JST)

        /// start
        vm.startPrank(investorA); // by contract investor
        vm.warp(timestamp);

        vm.expectRevert(
            abi.encodeWithSelector(
                ProvidedAmountIsEmpty.selector,
                address(investorA),
                _amount
            )
        );
        /// call claim
        hibco.claim();

        /// end
        vm.stopPrank();
    }

    function test_Fail_HegicInitialBondingCurve_withdrawProvidedETH_OfferingMustBeCompleted()
        public
    {
        /// timestamp value
        timestamp = 1700967650; // 2023-11-26-12:00(JST)

        /// start
        vm.startPrank(owner); // by owner
        vm.warp(timestamp);
        vm.expectRevert(
            abi.encodeWithSelector(
                OfferingMustBeCompleted.selector,
                address(owner),
                timestamp
            )
        );
        /// call withdrawProvidedETH
        hibco.withdrawProvidedETH();
        /// end
        vm.stopPrank();
    }

    function test_Fail_HegicInitialBondingCurve_withdrawProvidedETH_TotalProvidedIsLessThanMinimalProvideAmount()
        public
    {
        /// dummy provided amount
        uint256 provided = 0;
        /// timestamp value
        timestamp = 1701399650; // 2023-12-01-12:00(JST)

        /// start
        vm.startPrank(owner); // by owner
        vm.warp(timestamp);
        vm.expectRevert(
            abi.encodeWithSelector(
                TotalProvidedIsLessThanMinimalProvideAmount.selector,
                address(owner),
                provided
            )
        );
        /// call withdrawProvidedETH
        hibco.withdrawProvidedETH();
        /// end
        vm.stopPrank();
    }

    function test_Fail_HegicInitialBondingCurve_withdrawHEGIC_OfferingMustBeCompleted()
        public
    {
        /// timestamp value
        timestamp = 1700967650; // 2023-11-26-12:00(JST)

        /// start
        vm.startPrank(owner); // by owner
        vm.warp(timestamp);
        vm.expectRevert(
            abi.encodeWithSelector(
                OfferingMustBeCompleted.selector,
                address(owner),
                timestamp
            )
        );
        /// call withdrawHEGIC
        hibco.withdrawHEGIC();
        /// end
        vm.stopPrank();
    }

    function test_Fail_HegicInitialBondingCurve_withdrawUnclaimedHEGIC_WithdrawUnavailableYet()
        public
    {
        /// timestamp value
        timestamp = 1700967650; // 2023-11-26-12:00(JST)

        /// start
        vm.startPrank(owner); // by owner
        vm.warp(timestamp);
        vm.expectRevert(
            abi.encodeWithSelector(
                WithdrawUnavailableYet.selector,
                address(owner),
                timestamp
            )
        );
        /// call withdrawUnclaimedHEGIC
        hibco.withdrawUnclaimedHEGIC();
        /// end
        vm.stopPrank();
    }

    function test_Fail_withdrawProvidedETH_byInvestor() public {
        bool result = false;
        assertTrue(!result);

        vm.prank(investorA);
        vm.expectRevert(bytes("caller is only owner."));
        hibco.withdrawProvidedETH();

        assertTrue(!result);
    }

    function test_Fail_withdrawHEGIC_byInvestor() public {
        bool result = false;
        assertTrue(!result);

        vm.prank(investorA);
        vm.expectRevert(bytes("caller is only owner."));
        hibco.withdrawHEGIC();

        assertTrue(!result);
    }

    function test_Fail_withdrawUnclaimedHEGIC_byInvestor() public {
        bool result = false;
        assertTrue(!result);

        vm.prank(investorA);
        vm.expectRevert(bytes("caller is only owner."));
        hibco.withdrawHEGIC();

        assertTrue(!result);
    }
}
