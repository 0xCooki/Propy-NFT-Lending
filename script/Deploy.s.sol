// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "forge-std/Script.sol";

import {PropyNFTLoan} from "../contract/PropyNFTLoan.sol";
import {PropyNFTLoanFactory} from "../contract/PropyNFTLoanFactory.sol";
import {IPropyClaimAddressV1} from "../contract/interfaces/IPropyClaimAddressV1.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        /// @dev Assumed to be deploying to Base.
        IPropyClaimAddressV1 propyClaimAddress = IPropyClaimAddressV1(0xa239b9b3E00637F29f6c7C416ac95127290b950E);
        IERC20 USDC = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);

        PropyNFTLoanFactory factory = new PropyNFTLoanFactory(propyClaimAddress, USDC);
        factory;
        /// @dev Consider creating a loan here so that both contracts can be verified on deployment.
        
        vm.stopBroadcast();
    }
}