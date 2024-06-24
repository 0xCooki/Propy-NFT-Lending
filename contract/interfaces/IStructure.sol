// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IStructure {
    error NotBorrower();
    error NotLender();
    error WrongStatus();
    error LoanDurationHasNotPassed();
    error GracePeriodHasNotPassed();
    error HasNotClaimedCollateral();
    error AlreadyClaimed();
    error Zero();

    /// @dev legacy
    struct Token {
        uint256 tokenTier;
        uint256 tokenId;
        string tokenURI;
        bool isMetadataLocked;
    }

    enum LoanStatus {
        PreLoan,
        InLoan,
        AfterLoan
    }

    event LoanCancelled();
    event Lend(address _lender, uint256 _loanStart);
    event Repay();
    event CollateralClaimed();
    event CollateralRedeemed();
}