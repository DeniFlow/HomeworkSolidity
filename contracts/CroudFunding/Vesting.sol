// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/finance/VestingWallet.sol";

contract Vesting is VestingWallet
{

    constructor(address _fundriser, uint256 _durationSeconds) VestingWallet(_fundriser,uint64(block.timestamp),uint64(_durationSeconds)) {

    }
}