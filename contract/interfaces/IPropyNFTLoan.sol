// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IStructure} from "./IStructure.sol";

interface IPropyNFTLoan is IStructure {
    function cancelLoan() external;
    function lend() external;
    function repay() external;
    function claimCollateral() external;
    function redeemCollateral() external;
    function amountOwed() external view returns (uint256 _amount);
}