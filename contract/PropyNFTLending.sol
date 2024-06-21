// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {AccessControl} from "@openzeppelin/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";

contract PropyNFTLending is AccessControl, ReentrancyGuard {

    constructor() {}
}