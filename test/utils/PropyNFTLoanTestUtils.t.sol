// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {PropyNFTLoan} from "../../contract/PropyNFTLoan.sol";
import {PropyNFTLoanFactory} from "../../contract/PropyNFTLoanFactory.sol";
import {IStructure} from "../../contract/interfaces/IStructure.sol";
import {IPropyClaimAddressV1} from "../../contract/interfaces/IPropyClaimAddressV1.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract PropyNFTLoanTestUtils is Test, IStructure {
    uint256 public constant SECONDS_IN_A_YEAR = 31536000;
    uint256 public constant BASIS_POINT_APR_FACTOR = 3170979;

    IPropyClaimAddressV1 public propyClaimAddress;
    IERC20 public USDC;

    PropyNFTLoanFactory public factory;
    
    address public borrower;
    address public lender;

    /// @dev Use for easy updating
    uint256[5] public borrowerTokenIds;

    function setUp() public virtual {
        string memory rpcURL = vm.envString("BASE_RPC_URL");
        uint256 mainnetFork = vm.createFork(rpcURL);
        vm.selectFork(mainnetFork);

        borrower = 0x3241D662d5fb74f962607c8859Cb3c89CD7AdBeA; /// largest holder
        lender = makeAddr("LENDER");

        borrowerTokenIds[0] = 220262;
        borrowerTokenIds[1] = 220255;
        borrowerTokenIds[2] = 220261;
        borrowerTokenIds[3] = 220260;
        borrowerTokenIds[4] = 220251;
        
        propyClaimAddress = IPropyClaimAddressV1(0xa239b9b3E00637F29f6c7C416ac95127290b950E);
        USDC = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);

        factory = new PropyNFTLoanFactory(propyClaimAddress, USDC);

        vm.deal(borrower, 1e18);
        vm.deal(lender, 1e18);
        deal(address(USDC), lender, 1e18);

        vm.prank(borrower);
        propyClaimAddress.setApprovalForAll(address(factory), true);
    }

    modifier prank(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }
}