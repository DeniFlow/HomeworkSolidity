// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "Factory/IUtilityContract.sol";

contract BigBoss is IUtilityContract {

    error AlreadyInitialized();

    uint256 public number;
    address public bigBoss;

    modifier notInitialized() {
        require(!isInitialized,AlreadyInitialized());
        _;
    }

    

    bool private isInitialized;

    function initialize(bytes memory _initData) external notInitialized returns(bool) {
        
        (number,bigBoss) = abi.decode(_initData, (uint256,address));
        isInitialized = true;
        return true;
        
    }

    function doSmth() external view returns(uint256,address) {
        return (number,bigBoss);
    }

    function getInitData(uint256 _number,address _bigBoss) pure external returns (bytes memory) {
        return abi.encode(_number,_bigBoss);
    }


}