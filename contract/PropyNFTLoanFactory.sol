// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";
import {PropyNFTLoan} from "./PropyNFTLoan.sol";
import {IPropyClaimAddressV1} from "./interfaces/IPropyClaimAddressV1.sol";
import {IPropyNFTLoanFactory} from "./interfaces/IPropyNFTLoanFactory.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

/// @title  Propy NFT Loan Factory
/// @notice This contract allows users to create Propy NFT Loan contracts, each representing an isolated
///         loan. Each loan is collateralised with a Propy NFT, with the borrowed amount in USDC, interest
///         rate, and duration defined by the borrower.
contract PropyNFTLoanFactory is IPropyNFTLoanFactory, ReentrancyGuard {

    /// @notice The Propy NFT.
    IPropyClaimAddressV1 public immutable propyClaimAddress;

    /// @notice USDC ERC20.
    /// @dev    6 decimals.
    IERC20 public immutable USDC;

    constructor(IPropyClaimAddressV1 _propyClaimAddress, IERC20 _USDC) {
        propyClaimAddress = _propyClaimAddress;
        USDC = _USDC;
    }

    /// @notice This function allows users to create Propy NFT Loan contracts.
    /// @param  _tokenId The token Id of the Propy NFT to be used as loan collateral.
    /// @param  _amount The initial loan amount in USDC.
    /// @param  _rate The rate of interest per second. Use the aprToRate() function to assist in defining
    ///         this rate of interest.
    /// @param  _duration The duration of the loan. During this period the NFT collateral may not be 
    ///         claimed by the lender.
    /// @return _loan The address of the newly deployed loan contract.
    /// @dev    Borrower must grant this contract approval to move their Propy NFT.
    ///         _amount, _rate, and _duration must be non-zero.
    function createNewLoan(
        uint256 _tokenId, 
        uint256 _amount, 
        uint256 _rate, 
        uint256 _duration
    ) external nonReentrant returns (address _loan) {
        if (_amount == 0 || _rate == 0 || _duration == 0) revert Zero();
        PropyNFTLoan loan = new PropyNFTLoan(
            propyClaimAddress,
            USDC,
            msg.sender, 
            _tokenId,
            90 days,
            _amount,
            _rate, 
            _duration
        );
        _loan = address(loan);
        propyClaimAddress.transferFrom(msg.sender, _loan, _tokenId);
    }

    /// @notice This function provides a simple way for borrowers to determined a desired loan rate. 
    /// @param  _apr The desired loan APR (Annual Percentage Return), defined using basis points (0.01%).
    /// @return _rate The rate of interest per second that can be used to defined a new loan.
    /// @dev    1 = 0.01% APR
    ///         10000 = 100% APR
    function aprToRate(uint256 _apr) external pure returns (uint256 _rate) {
        _rate = _apr * 3170979;
    }
}