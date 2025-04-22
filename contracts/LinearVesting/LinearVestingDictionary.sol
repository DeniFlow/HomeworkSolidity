//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/Factory/IUtilityContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LinearVestingDictionary is IUtilityContract,Ownable {

    error AlreadyInitialized();
    error ClaimerIsNotBeneficiary();
    error CliffNotReached();
    error NothingToClaim();
    error TransferFailed();
    error NotEnoughTokens();
    error NotEnoughTimeHasPassed();
    error NotEnoughTokensForClaim();
    error VestingHasEnded();

    event Claim(address beneficiary,uint256 amount,uint256 timestamp);
    event StartVesting(uint256 startTime, uint256 cliff, uint256 duration, uint256 totalAmount, uint256 minClaimTokens);

    constructor() Ownable(msg.sender) {}

    struct Beneficiary  {
        address addr;
        uint256 amount;
        uint256 claimedTokens;
        uint256 timestampReceivedTokens;
        uint256 registeredAt;

    }


    bool private isInitialized;
    IERC20 public token;
    mapping (address => Beneficiary) public beneficiaries;
    uint256 public totalAmount;
    uint256 public startTime;
    uint256 public cliff;
    uint256 public duration;
    uint256 public claimed;
    uint256 public minClaimTokens;
    uint256 public cooldown;


    modifier notInitialize() {
        require(!isInitialized,AlreadyInitialized());
        _;
    }

    function claim() public {

        Beneficiary storage beneficiary = beneficiaries[msg.sender];
        require(block.timestamp <= startTime + duration, VestingHasEnded());
        require(beneficiary.registeredAt > 0,ClaimerIsNotBeneficiary());
        require(block.timestamp > startTime+cliff,CliffNotReached());
        require(beneficiary.timestampReceivedTokens + cooldown <= block.timestamp,NotEnoughTimeHasPassed());

        uint256 claimable = claimableAmount(msg.sender);

        require(claimable >= minClaimTokens,NotEnoughTokensForClaim());
        require(totalAmount - claimed > 0,NothingToClaim());

        claimed += claimable;
        beneficiary.claimedTokens += claimable;
        beneficiary.timestampReceivedTokens = block.timestamp;
        require(token.transfer(beneficiaries[msg.sender].addr, claimable),TransferFailed());

        emit Claim(beneficiaries[msg.sender].addr, claimable, block.timestamp);


    }

    function vestedAmount(address _beneficiary) internal  view  returns (uint256) {
        if (block.timestamp < startTime + cliff) {
            return 0;
        }
        uint256 passedTime = block.timestamp - (startTime + cliff);
        return (beneficiaries[_beneficiary].amount * passedTime) / duration;
    }

    function claimableAmount(address _beneficiary) public view returns (uint256){
        return vestedAmount(_beneficiary) - beneficiaries[_beneficiary].claimedTokens;
    }

    function addBeneficiary(address _addr, uint256 _amount) external onlyOwner {
        beneficiaries[_addr] = Beneficiary(_addr,_amount,0,0,block.timestamp);
    }




    function initialize(bytes memory _initData) external notInitialize returns(bool){
    
        (address _token,address _owner) = abi.decode(_initData, (address,address));
        token = IERC20(_token);
        Ownable.transferOwnership(_owner);
        isInitialized = true;
        return true;
    }

    function startVesting(uint256 _startTime, uint256 _cliff, uint256 _duration, uint256 _totalAmount, uint256 _minClaimTokens,uint256 _cooldown) public onlyOwner {
        require(token.balanceOf(address(this)) >= _totalAmount,NotEnoughTokens());
        startTime = _startTime;
        cliff = _cliff;
        duration = _duration;
        totalAmount = _totalAmount;
        minClaimTokens = _minClaimTokens;
        cooldown = _cooldown;

        emit StartVesting(startTime, cliff, duration,totalAmount,minClaimTokens);
    }

    function getInitData(address _token, address _owner) external pure returns (bytes memory) {
        return abi.encode(_token,_owner);
    }

}