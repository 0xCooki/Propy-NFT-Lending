// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC721} from "@openzeppelin/token/ERC721/IERC721.sol";
import {IStructure} from "./IStructure.sol";

interface IPropyClaimAddressV1 is IStructure, IERC721 {
    function mint(address _to,string memory _tokenURI) external;

    function updateTokenNameAndSymbol(string memory _tokenName,string memory _tokenSymbol) external;
    function updateContractURI(string memory _contractURI) external;
    function updateTokenTier(uint256 _tokenId,uint256 _tokenTier) external;
    function updateTokenURI(uint256 _tokenId,string memory _tokenURI) external;
    function updateTokenTierAndURI(uint256 _tokenId,uint256 _tokenTier,string memory _tokenURI) external;

    function contractURI() external returns(string memory);
    function name() external view  returns (string memory);
    function symbol() external view returns (string memory);
    function tokenInfo(uint256 _tokenId) external view returns (Token memory);
    function tokenTier(uint256 _tokenId) external view returns (uint256);
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function lockMetadata(uint256 _tokenId) external;
    function unlockMetadata(uint256 _tokenId) external;
}