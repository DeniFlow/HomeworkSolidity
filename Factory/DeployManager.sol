// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "Factory/IUtilityContract.sol";

contract DeployManager is Ownable {

    error ContractNotActive();
    error NotEnoughtFunds();
    error ContractDoesNotRegistered();
    error InitializeFailed();

    event NewContractAdded(address _contractAddress,uint256 _fee, bool _isActive, uint256 _timestamp);
    event ContractFeeUpdated(address _contractAddress, uint256 _oldFee, uint256 _newFee, uint256 _timestamp);
    event ContractStatusUpdated(address _contractAddress, bool _isActive, uint256 _timestamp);
    event NewDeployment(address _contractAddress,address deployer,uint256 _fee, uint256 _timestamp);
    

    constructor() Ownable(msg.sender) {

    }


    

    struct ContractInfo {
        uint256 fee;
        bool isActive;
        uint256 registeredAt;

    }

    mapping(address => address[]) public deployedContracts;
    mapping(address => ContractInfo) public contractsData;

    function deploy(address _utilityContract, bytes calldata _initData) external payable returns(address) {
        ContractInfo memory info = contractsData[_utilityContract];

        require(info.isActive,ContractNotActive());
        require(msg.value >= info.fee, NotEnoughtFunds());
        require(info.registeredAt > 0, ContractDoesNotRegistered());

        address newContract = Clones.clone(_utilityContract);

        require(IUtilityContract(newContract).initialize(_initData),InitializeFailed());

        payable(owner()).transfer(msg.value);

        deployedContracts[msg.sender].push(newContract);

        emit NewDeployment(newContract,msg.sender, msg.value, block.timestamp);

        return newContract;
        


    }

    function addNewContract(address _contractAddress,uint256 _fee, bool _isActive) external onlyOwner {
        contractsData[_contractAddress] = ContractInfo({
            fee: _fee,
            isActive: _isActive,
            registeredAt: block.timestamp
            });
        emit NewContractAdded(_contractAddress, _fee, _isActive, block.timestamp);
        
    }

    function updateFee(address _contractAddress, uint256 _newFee) external onlyOwner {
        require(contractsData[_contractAddress].registeredAt > 0,ContractDoesNotRegistered());
        uint256 oldFee = contractsData[_contractAddress].fee;
        contractsData[_contractAddress].fee = _newFee;

        emit ContractFeeUpdated(_contractAddress,oldFee,_newFee,block.timestamp);

    }

    function deactivateContract(address _contractAddress) external onlyOwner{
        require(contractsData[_contractAddress].registeredAt > 0,ContractDoesNotRegistered());
        contractsData[_contractAddress].isActive = false;
        emit ContractStatusUpdated(_contractAddress,false, block.timestamp);
    }

    function activateContract(address _contractAddress) external onlyOwner{
        require(contractsData[_contractAddress].registeredAt > 0,ContractDoesNotRegistered());
        contractsData[_contractAddress].isActive = true;
        emit ContractStatusUpdated(_contractAddress,true, block.timestamp);
    }
}