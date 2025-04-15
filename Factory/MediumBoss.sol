//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "Factory/IUtilityContract.sol";

contract MediumBoss is IUtilityContract {

    error AlreadyInitialized();

    IERC20 public token;
    uint256 public amount; //100 000
    bool private isInitialized;

    

    modifier notInitialize() {
        require(!isInitialized,AlreadyInitialized());
        _;
    }

    function initialize(bytes memory _initData) external notInitialize returns(bool){
        (token,amount) = abi.decode(_initData, (IERC20,uint256));
        isInitialized = true;
        return true;
    }
    

    function airdrop(address[] calldata receivers, uint256[] calldata amounts) external {
        require(receivers.length == amounts.length, "arrays length mismatch");
        require(token.allowance(msg.sender, address(this)) >= amount, "not enought approved tokens");

        for (uint256 i = 0; i < receivers.length; i++) {
            require(token.transferFrom(msg.sender, receivers[i], amounts[i]), "transfer failed");
        }

    }

    function getInitData(address _tokenAddress, uint256 _airdropAmount) external pure  returns(bytes memory) {
        return abi.encode(_tokenAddress,_airdropAmount);
    }

    function doSmth() external view returns(IERC20,uint256) {
        return (token,amount);
    }

}