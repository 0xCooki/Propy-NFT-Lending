// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {
    PropyNFTLoanTestUtils,
    PropyNFTLoan
} from "./utils/PropyNFTLoanTestUtils.t.sol";

contract PropyNFTLoanFactoryTest is PropyNFTLoanTestUtils {
    function testInit() public {
        assertEq(address(factory.propyClaimAddress()), address(propyClaimAddress));
        assertEq(address(factory.USDC()), address(USDC));
    }

    function testCreateNewLoanRevertConditions() public prank(borrower) {
        /// Deposit zero
        vm.expectRevert(Zero.selector);
        factory.createNewLoan(borrowerTokenIds[0], 0, 1, 1);
        vm.expectRevert(Zero.selector);
        factory.createNewLoan(borrowerTokenIds[0], 1, 0, 1);
        vm.expectRevert(Zero.selector);
        factory.createNewLoan(borrowerTokenIds[0], 1, 1, 0);
    }

    function testCreateNewLoanSuccessConditions() public prank(borrower) {
        address _loan = factory.createNewLoan(borrowerTokenIds[0], 1e8, 1, 100 days);
        PropyNFTLoan loan = PropyNFTLoan(_loan);

        assertEq(address(loan.propyClaimAddress()), address(propyClaimAddress));
        assertEq(address(loan.USDC()), address(USDC));
        assertEq(loan.tokenId(), borrowerTokenIds[0]);
        assertEq(loan.gracePeriod(), 90 days);
        assertEq(loan.amount(), 1e8);
        assertEq(loan.rate(), 1);
        assertEq(loan.duration(), 100 days);
        assertEq(loan.borrower(), borrower);
        assertEq(loan.lender(), address(0));
        assertEq(loan.loanStart(), 0);
        assertEq(loan.claimStart(), 0);
        assertEq(loan.amountOwed(), 0);
        assert(loan.status() == LoanStatus.PreLoan);
        assertEq(propyClaimAddress.ownerOf(borrowerTokenIds[0]), address(loan));
    }

    function testCreateMultipleLoans() public prank(borrower) {
        address _loan0 = factory.createNewLoan(borrowerTokenIds[0], 1e8, 1, 100 days);

        /// Should fail given no longer owner of NFT
        vm.expectRevert();
        factory.createNewLoan(borrowerTokenIds[0], 1e8, 1, 100 days);

        address _loan1 = factory.createNewLoan(borrowerTokenIds[1], 1e8, 1, 100 days);
        assert(_loan0 != _loan1);
    }
}