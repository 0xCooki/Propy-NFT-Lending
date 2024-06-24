// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {IPropyClaimAddressV1} from "./interfaces/IPropyClaimAddressV1.sol";
import {IPropyNFTLoan} from "./interfaces/IPropyNFTLoan.sol";

/// @title  Propy NFT Loan
/// @notice This contract enforces a simple USDC loan against a Propy NFT as collateral. The borrower,
///         when creating the loan with the loan factory, specifies the Propy NFT collateral asset, the
///         loan amount, interest rate, and duration.
contract PropyNFTLoan is IPropyNFTLoan, ReentrancyGuard {

    /// @notice The Propy NFT.
    IPropyClaimAddressV1 public immutable propyClaimAddress;

    /// @notice USDC ERC20.
    /// @dev    6 decimals.
    IERC20 public immutable USDC;

    /// @notice The token Id of the Propy NFT used as collateral.
    uint256 public immutable tokenId;

    /// @notice The grace period, allowing the borrower to repay the loan before lender redemption.
    uint256 public immutable gracePeriod;
    
    /// @notice The principle amount of the loan.
    uint256 public immutable amount;

    /// @notice The rate of interest per second.
    /// @dev    18 decimals.
    uint256 public immutable rate;

    /// @notice The duration of the loan. During this period the borrower may repay the loan early.
    /// @dev    The lender may not claim the colleteral during the duration of the loan, only after expiry.
    uint256 public immutable duration;

    /// @notice The borrower of the loan, who uses their NFT as collateral for a USDC loan.
    address public immutable borrower;

    /// @notice The lender who provides liquidity to the borrower, with claims over the NFT collateral
    ///         if the borrower fails to repay the loan plus accrued interest.
    address public lender;
    
    /// @notice The timestamp of when the loan was started by the lender.
    uint256 public loanStart;

    /// @notice The timestamp of when the collateral was claimed.
    uint256 public claimStart;

    /// @notice The current loan status:
    ///         PreLoan: Borrower can cancel loan, and anyone can become lender.
    ///         InLoan: Borrower may repay loan, and lender can claim and redeem collateral.
    ///         AfterLoan: Loan finalised. Either canceled, repayed, or collateral claimed.
    /// @dev    Provides access control to the contract functions.
    LoanStatus public status;

    constructor(
        IPropyClaimAddressV1 _propyClaimAddress,
        IERC20 _USDC,
        address _borrower,
        uint256 _tokenId,
        uint256 _gracePeriod,
        uint256 _amount,
        uint256 _rate,
        uint256 _duration
    ) {
        propyClaimAddress = _propyClaimAddress;
        USDC = _USDC;
        tokenId = _tokenId;
        gracePeriod = _gracePeriod;
        borrower = _borrower;
        amount = _amount;
        rate = _rate;
        duration = _duration;
    }

    /// PRELOAN ///

    /// @notice This function allows the borrower to cancel the loan before anyone has accepted it.
    /// @dev    Must be in PreLoan status.
    ///         Can only be called by the borrower.
    function cancelLoan() external nonReentrant {
        if (status != LoanStatus.PreLoan) revert WrongStatus();
        if (msg.sender != borrower) revert NotBorrower();
        propyClaimAddress.transferFrom(address(this), borrower, tokenId);
        status = LoanStatus.AfterLoan;
        emit LoanCancelled();
    }

    /// @notice This function allows anyone to become the lender for this loan.
    /// NOTE    Lenders must take extreme caution when accepting the loan conditions. Lenders must
    ///         ensure they understand and accept the full loan conditions as defined by the borrower.
    /// @dev    Must be in PreLoan status.
    ///         Lender must grant this contract approval to move their USDC.
    function lend() external nonReentrant {
        if (status != LoanStatus.PreLoan) revert WrongStatus();
        USDC.transferFrom(msg.sender, borrower, amount);
        lender = msg.sender;
        loanStart = block.timestamp;
        status = LoanStatus.InLoan;
        emit Lend(msg.sender, block.timestamp);
    }

    /// INLOAN ///

    /// @notice This function allows the borrower to repay the loan amount, plus accrued interest, to 
    ///         the lender. This returns the collateral NFT to the borrower and ends the loan.
    /// @dev    Must be in InLoan status.
    ///         Can only be called by the borrower.
    ///         Borrower must grant this contract approval to move their USDC.
    function repay() external nonReentrant {
        if (status != LoanStatus.InLoan) revert WrongStatus();
        if (msg.sender != borrower) revert NotBorrower();
        USDC.transferFrom(msg.sender, lender, amountOwed());
        propyClaimAddress.transferFrom(address(this), borrower, tokenId);
        status = LoanStatus.AfterLoan;
        emit Repay();
    }
    
    /// @notice This function allows the lender to make a claim for the loan collateral, this initiates
    ///         the loan liquidation process.
    /// @dev    Must be in InLoan status.
    ///         Can only be called by the lender.
    ///         Loan duration must have passed.
    ///         Can only claim once.
    function claimCollateral() external nonReentrant {
        if (status != LoanStatus.InLoan) revert WrongStatus();
        if (msg.sender != lender) revert NotLender();
        if (block.timestamp - loanStart < duration) revert LoanDurationHasNotPassed();
        if (claimStart != 0) revert AlreadyClaimed();
        claimStart = block.timestamp;
        emit CollateralClaimed();
    }

    /// @notice This function allows the lender to redeem the loan collateral after the claim grace period
    ///         has passed. 
    /// @dev    Must be in InLoan status.
    ///         Can only be called by the lender.
    ///         Grace period must have passed.
    function redeemCollateral() external nonReentrant {
        if (status != LoanStatus.InLoan) revert WrongStatus();
        if (msg.sender != lender) revert NotLender();
        if (claimStart == 0) revert HasNotClaimedCollateral();
        if (block.timestamp - claimStart < gracePeriod) revert GracePeriodHasNotPassed();
        /// @dev Update Propy metadata here?
        propyClaimAddress.transferFrom(address(this), lender, tokenId);
        status = LoanStatus.AfterLoan;
        emit CollateralRedeemed();
    }

    /// VIEWS ///
    
    /// @notice This view function retuns the amount of USDC that the borrower owes to the lender.
    /// @return _amount The amount of USDC owed.
    /// @dev    USDC has 6 decimals.
    function amountOwed() public view returns (uint256 _amount) {
        if (status != LoanStatus.InLoan) return 0;
        _amount = amount + ((amount * rate * (block.timestamp - loanStart)) / 1e18);
    }
}