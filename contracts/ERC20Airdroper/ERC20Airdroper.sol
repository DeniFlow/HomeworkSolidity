//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/Factory/IUtilityContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Airdroper is IUtilityContract,Ownable {

    error AlreadyInitialized();
    error ArraysLengthMismatch();
    error NotEnougApprovedTokens();
    error TransferFailed();

    constructor() Ownable(msg.sender) {}

    IERC20 public token;
    uint256 public amount; //100 000
    address public treasury;
    bool private isInitialized;

    

    modifier notInitialize() {
        require(!isInitialized,AlreadyInitialized());
        _;
    }

    function initialize(bytes memory _initData) external notInitialize returns(bool){
    
        (address _token,uint256 _amount,address _treasury,address _owner) = abi.decode(_initData, (address,uint256,address,address));
        token = IERC20(_token);
        amount = _amount;
        treasury = _treasury;
        Ownable.transferOwnership(_owner);
        isInitialized = true;
        return true;
    }
    

    function airdrop(address[] calldata receivers, uint256[] calldata amounts) external onlyOwner {
        require(receivers.length == amounts.length, ArraysLengthMismatch());
        require(token.allowance(treasury, address(this)) >= amount, NotEnougApprovedTokens());

        for (uint256 i = 0; i < receivers.length; i++) {
            require(token.transferFrom(treasury, receivers[i], amounts[i]), TransferFailed());
        }

    }

    function getInitData(address _tokenAddress, uint256 _airdropAmount,address _treasury, address _owner) external pure  returns(bytes memory) {
        return abi.encode(_tokenAddress,_airdropAmount,_treasury,_owner);
    }

    function doSmth() external view returns(IERC20,uint256) {
        return (token,amount);
    }

}

// ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB","0x617F2E2fD72FD9D5503197092aC168c91465E7f2"]
// [1000000000,20000000000,5000000000,999999999999]