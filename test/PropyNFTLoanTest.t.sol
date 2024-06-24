// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {
    PropyNFTLoanTestUtils,
    PropyNFTLoan,
    console
} from "./utils/PropyNFTLoanTestUtils.t.sol";

contract PropyNFTLoanTest is PropyNFTLoanTestUtils {

    /// CANCEL LOAN ///

    function testCancelLoanRevertConditions() public {
        vm.prank(borrower);
        address _loan = factory.createNewLoan(borrowerTokenIds[0], 1e8, 1, 100 days);
        PropyNFTLoan loan = PropyNFTLoan(_loan);

        /// Not borrower
        vm.expectRevert(NotBorrower.selector);
        loan.cancelLoan();

        /// Wrong status
        vm.startPrank(lender);
        USDC.approve(address(loan), ~uint256(0));
        loan.lend();

        vm.expectRevert(WrongStatus.selector);
        loan.cancelLoan();
        vm.stopPrank();
    }

    function testCancelLoanSuccess() public prank(borrower) {
        address _loan = factory.createNewLoan(borrowerTokenIds[0], 1e8, 1, 100 days);
        PropyNFTLoan loan = PropyNFTLoan(_loan);

        assert(loan.status() == LoanStatus.PreLoan);
        assertEq(propyClaimAddress.ownerOf(borrowerTokenIds[0]), address(loan));
        
        vm.expectEmit(true, true, true, true);
        emit LoanCancelled();
        loan.cancelLoan();

        assert(loan.status() == LoanStatus.AfterLoan);
        assertEq(propyClaimAddress.ownerOf(borrowerTokenIds[0]), address(borrower));
    }

    /// LEND ///

    function testLendRevertConditions() public {
        /// Transfer failure
        vm.prank(borrower);
        address _loan = factory.createNewLoan(borrowerTokenIds[0], 1e20, 1, 100 days);
        PropyNFTLoan loan = PropyNFTLoan(_loan);

        vm.startPrank(lender);
        USDC.approve(address(loan), ~uint256(0));

        vm.expectRevert();
        loan.lend();
        vm.stopPrank();

        /// Wrong status
        vm.prank(borrower);
        loan.cancelLoan();

        vm.startPrank(lender);
        vm.expectRevert(WrongStatus.selector);
        loan.lend();
    }

    function testLendSuccess() public {
        uint256 amount = 1e12;

        vm.prank(borrower);
        address _loan = factory.createNewLoan(borrowerTokenIds[0], amount, 1, 100 days);
        PropyNFTLoan loan = PropyNFTLoan(_loan);

        uint256 lenderUSDCBalanceBefore = USDC.balanceOf(lender);
        uint256 borrowerUSDCBalanceBefore = USDC.balanceOf(borrower);

        vm.startPrank(lender);
        USDC.approve(address(loan), ~uint256(0));

        vm.expectEmit(true, true, true, true);
        emit Lend(lender, block.timestamp);
        loan.lend();
        vm.stopPrank();

        assertEq(USDC.balanceOf(lender), lenderUSDCBalanceBefore - amount);
        assertEq(USDC.balanceOf(borrower), borrowerUSDCBalanceBefore + amount);
        assertEq(loan.lender(), lender);
        assertEq(loan.loanStart(), block.timestamp);
        assert(loan.status() == LoanStatus.InLoan);
    }

    /// REPAY ///

    function testRepayRevertConditions() public {
        uint256 amount = 1e12;

        vm.prank(borrower);
        address _loan = factory.createNewLoan(borrowerTokenIds[0], amount, 1, 100 days);
        PropyNFTLoan loan = PropyNFTLoan(_loan);

        /// Wrong status
        vm.expectRevert(WrongStatus.selector);
        loan.repay();

        vm.startPrank(lender);
        USDC.approve(address(loan), ~uint256(0));
        loan.lend();
        
        /// Not Borrower
        vm.expectRevert(NotBorrower.selector);
        loan.repay();

        vm.stopPrank();
        vm.startPrank(borrower);
        /// Approval

        deal(address(USDC), borrower, 2 * amount);

        vm.expectRevert();
        loan.repay();
    }

    function testRepayImmediately() public {
        uint256 amount = 1e12;
        uint256 time = 0;
        deal(address(USDC), borrower, 2 * amount);

        vm.prank(borrower);
        address _loan = factory.createNewLoan(borrowerTokenIds[0], amount, 1, 100 days);
        PropyNFTLoan loan = PropyNFTLoan(_loan);

        vm.startPrank(lender);
        USDC.approve(address(loan), ~uint256(0));
        loan.lend();
        vm.stopPrank();

        vm.warp(block.timestamp + time);
        vm.startPrank(borrower);

        uint256 amountOwed = loan.amountOwed();
        uint256 lenderUSDCBalanceBefore = USDC.balanceOf(lender);
        uint256 borrowerUSDCBalanceBefore = USDC.balanceOf(borrower);

        USDC.approve(address(loan), ~uint256(0));
        loan.repay();

        assertEq(USDC.balanceOf(lender), lenderUSDCBalanceBefore + amountOwed);
        assertEq(USDC.balanceOf(borrower), borrowerUSDCBalanceBefore - amountOwed);
        assertEq(propyClaimAddress.ownerOf(borrowerTokenIds[0]), borrower);
        assert(loan.status() == LoanStatus.AfterLoan);

        vm.stopPrank();
    }

    function testRepayAfterOneYear() public {
        uint256 amount = 1e12;
        uint256 rate = factory.aprToRate(5000); /// 50% apr
        uint256 time = SECONDS_IN_A_YEAR;
        deal(address(USDC), borrower, 2 * amount);

        vm.prank(borrower);
        address _loan = factory.createNewLoan(borrowerTokenIds[0], amount, rate, time);
        PropyNFTLoan loan = PropyNFTLoan(_loan);

        vm.startPrank(lender);
        USDC.approve(address(loan), ~uint256(0));
        loan.lend();
        vm.stopPrank();

        vm.warp(block.timestamp + time);
        vm.startPrank(borrower);

        uint256 amountOwed = loan.amountOwed();
        uint256 lenderUSDCBalanceBefore = USDC.balanceOf(lender);
        uint256 borrowerUSDCBalanceBefore = USDC.balanceOf(borrower);

        USDC.approve(address(loan), ~uint256(0));
        loan.repay();

        assertEq(USDC.balanceOf(lender), lenderUSDCBalanceBefore + amountOwed);
        assertEq(USDC.balanceOf(borrower), borrowerUSDCBalanceBefore - amountOwed);
        assertEq(propyClaimAddress.ownerOf(borrowerTokenIds[0]), borrower);
        assert(loan.status() == LoanStatus.AfterLoan);

        vm.stopPrank();
    }

    function testRepayInGracePeriod() public {
        uint256 amount = 1e12;
        uint256 rate = factory.aprToRate(5000); /// 50% apr
        uint256 time = SECONDS_IN_A_YEAR;
        deal(address(USDC), borrower, 2 * amount);

        vm.prank(borrower);
        address _loan = factory.createNewLoan(borrowerTokenIds[0], amount, rate, time);
        PropyNFTLoan loan = PropyNFTLoan(_loan);

        vm.startPrank(lender);
        USDC.approve(address(loan), ~uint256(0));
        loan.lend();
        vm.warp(block.timestamp + time);
        loan.claimCollateral();
        vm.stopPrank();

        vm.warp(block.timestamp + 1);
        vm.startPrank(borrower);

        uint256 amountOwed = loan.amountOwed();
        uint256 lenderUSDCBalanceBefore = USDC.balanceOf(lender);
        uint256 borrowerUSDCBalanceBefore = USDC.balanceOf(borrower);

        USDC.approve(address(loan), ~uint256(0));
        loan.repay();

        assertEq(USDC.balanceOf(lender), lenderUSDCBalanceBefore + amountOwed);
        assertEq(USDC.balanceOf(borrower), borrowerUSDCBalanceBefore - amountOwed);
        assertEq(propyClaimAddress.ownerOf(borrowerTokenIds[0]), borrower);
        assert(loan.status() == LoanStatus.AfterLoan);

        vm.stopPrank();
    }

    /// CLAIM COLLATERAL ///

    function testCLaimCollateral() public {
        vm.prank(borrower);
        address _loan = factory.createNewLoan(borrowerTokenIds[0], 1e12, 1, 100 days);
        PropyNFTLoan loan = PropyNFTLoan(_loan);

        /// Wrong status
        vm.expectRevert(WrongStatus.selector);
        loan.claimCollateral();

        vm.startPrank(lender);
        USDC.approve(address(loan), ~uint256(0));
        loan.lend();
        vm.stopPrank();

        /// Not lender
        vm.startPrank(borrower);
        vm.expectRevert(NotLender.selector);
        loan.claimCollateral();
        vm.stopPrank();

        /// Loan duration hasn't passed
        vm.startPrank(lender);
        vm.expectRevert(LoanDurationHasNotPassed.selector);
        loan.claimCollateral();

        /// Already Claimed
        vm.warp(block.timestamp + loan.duration());
        loan.claimCollateral();

        vm.expectRevert(AlreadyClaimed.selector);
        loan.claimCollateral();
    }

    function testClaimCollateral() public {
        vm.prank(borrower);
        address _loan = factory.createNewLoan(borrowerTokenIds[0], 1e12, 1, 100 days);
        PropyNFTLoan loan = PropyNFTLoan(_loan);

        vm.startPrank(lender);
        USDC.approve(address(loan), ~uint256(0));
        loan.lend();
        vm.warp(block.timestamp + loan.duration());

        assertEq(loan.claimStart(), 0);

        vm.expectEmit(true, true, true, true);
        emit CollateralClaimed();
        loan.claimCollateral();
        vm.stopPrank();

        assertEq(loan.claimStart(), block.timestamp);
    }

    /// REDEEM COLLATERAL ///

    function testRedeemCollateralRevertConditions() public {
        uint256 time = 100 days;

        vm.prank(borrower);
        address _loan = factory.createNewLoan(borrowerTokenIds[0], 1e12, 1, time);
        PropyNFTLoan loan = PropyNFTLoan(_loan);

        /// Wrong status
        vm.expectRevert(WrongStatus.selector);
        loan.redeemCollateral();

        /// Hasn't claimed
        vm.startPrank(lender);
        USDC.approve(address(loan), ~uint256(0));
        loan.lend();
        
        vm.expectRevert(HasNotClaimedCollateral.selector);
        loan.redeemCollateral();

        vm.warp(block.timestamp + time);
        loan.claimCollateral();
        vm.stopPrank();

        /// Not lender
        vm.startPrank(borrower);
        vm.expectRevert(NotLender.selector);
        loan.redeemCollateral();
        vm.stopPrank();

        /// Grace period hasn't passed
        vm.startPrank(lender);
        vm.expectRevert(GracePeriodHasNotPassed.selector);
        loan.redeemCollateral();
        vm.stopPrank();
    }

    function testRedeemCollateral() public {
        uint256 amount = 1e12;
        uint256 time = 100 days;

        vm.prank(borrower);
        address _loan = factory.createNewLoan(borrowerTokenIds[0], amount, 1, time);
        PropyNFTLoan loan = PropyNFTLoan(_loan);

        vm.startPrank(lender);
        USDC.approve(address(loan), ~uint256(0));
        loan.lend();
        vm.warp(block.timestamp + time);
        loan.claimCollateral();

        vm.warp(block.timestamp + loan.gracePeriod());

        vm.expectEmit(true, true, true, true);
        emit CollateralRedeemed();
        loan.redeemCollateral();

        assertEq(propyClaimAddress.ownerOf(borrowerTokenIds[0]), lender);
        assert(loan.status() == LoanStatus.AfterLoan);
        assertEq(loan.amountOwed(), 0);
        vm.stopPrank();

        /// Borrower may not now repay
        deal(address(USDC), borrower, 2 * amount);
        vm.startPrank(borrower);
        USDC.approve(address(loan), ~uint256(0));

        vm.expectRevert(WrongStatus.selector);
        loan.repay();

        vm.stopPrank();
    }
}