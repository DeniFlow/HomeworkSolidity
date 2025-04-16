//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "contracts/Factory/IUtilityContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC1155Airdroper is IUtilityContract,Ownable {

    error AlreadyInitialized();
    error ArraysLengthMismatch();
    error NeedToApproveTokens();
    error TransferFailed();

    constructor() Ownable(msg.sender) {}

    IERC1155 public token;
    address public treasury;
    bool private isInitialized;

    

    modifier notInitialize() {
        require(!isInitialized,AlreadyInitialized());
        _;
    }

    function initialize(bytes memory _initData) external notInitialize returns(bool){
    
        (address _token,address _treasury,address _owner) = abi.decode(_initData, (address,address,address));
        token = IERC1155(_token);
        treasury = _treasury;
        Ownable.transferOwnership(_owner);
        isInitialized = true;
        return true;
    }
    

    function airdrop(address[] calldata receivers, uint256[] calldata amounts,uint256[] calldata tokenId) external onlyOwner {
        require(receivers.length == amounts.length && receivers.length == tokenId.length, ArraysLengthMismatch());
        require(token.isApprovedForAll(treasury,address(this)),NeedToApproveTokens());

        for (uint256 i = 0; i < receivers.length;i++) {
            token.safeTransferFrom(treasury, receivers[i], tokenId[i], amounts[i], "");
        }
        
    }

    function getInitData(address _tokenAddress,address _treasury, address _owner) external pure  returns(bytes memory) {
        return abi.encode(_tokenAddress,_treasury,_owner);
    }

    function doSmth() external view returns(IERC1155) {
        return token;
    }

}

