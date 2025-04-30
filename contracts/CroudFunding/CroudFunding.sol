// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "contracts/CroudFunding/Vesting.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CroudFunding is Ownable {
    
    // объявление ошибок

    error FundriserNotBeZeroAddress();
    error GoalShouldThanZero();
    error GoalComplete();
    error DonateShouldThanZero();
    error RefundUnavailable();
    error NothingToRefund();
    error VestingDurationShouldThanZero();
    error NotEnoughPermission();
    error GoalNotComplete();
    error VestingContractNotBeZeroAddress();
    error AlreadyInitialized();

    // объявление всех переменных

    address private fundriser;
    mapping (address => uint256) private investors;
    uint256 private goalInEth;
    uint256 private tempMoneyAmount;
    Vesting private vestingContract;
    uint256 private vestingDurationInSeconds;
    bool private isInitialized;

    // модификатор для функции Initialize, который позволяет вызвать данную функцию только единожды

    modifier NotInitialized() {
        require(!isInitialized,AlreadyInitialized());
        _;
    }

    // модификатор, ограничивающий обращение к функции, если ты не владелец контракта или сборщик средств краундфандинга

    modifier OnlyOnwerOrFundriser() {
        require(msg.sender == owner() || msg.sender == fundriser, NotEnoughPermission());
        _;
    }

    constructor () Ownable(msg.sender) {
        
    }

    // функция для внесения доната в краундфандинг 

    function contribute() external payable   {
        require(tempMoneyAmount < goalInEth,GoalComplete());
        require(msg.value > 0, DonateShouldThanZero());
        tempMoneyAmount = address(this).balance;
        investors[msg.sender] += msg.value;
        if (tempMoneyAmount >= goalInEth) {
            vestingContract = new Vesting(fundriser,vestingDurationInSeconds);
        }
    
    }

    // функция для возврата вложенных средств. Возврат возможен если цель краундфандинга ещё не выполнена

    function refund() external {
        require(tempMoneyAmount < goalInEth, RefundUnavailable());
        require(investors[msg.sender] > 0, NothingToRefund());
        uint256 amount = investors[msg.sender];
        tempMoneyAmount -= amount;
        investors[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // функция для вывода средств с CroudFunding контракта на Vesting контракт, где fundriser будет получать собранные средства в течении определенного времени

    function withdraw() OnlyOnwerOrFundriser external {
        require(tempMoneyAmount >= goalInEth,GoalNotComplete());
        require(address(vestingContract) != address(0),VestingContractNotBeZeroAddress());
        payable(vestingContract).transfer(address(this).balance);
    }

    function initialize(bytes memory _initData) NotInitialized external returns (bool) {
        (address _fundriser,address _owner, uint256 _goalInEth,uint256 _vestingDurationInSeconds) = abi.decode(_initData, (address,address,uint256,uint256));
        fundriser = _fundriser;
        goalInEth = _goalInEth * 10**18;
        vestingDurationInSeconds = _vestingDurationInSeconds;
        Ownable.transferOwnership(_owner);
        isInitialized = true;
        return true;
    }
    function getInitData
    (address _fundriser,
    address _owner,
    uint256 _goalInEth,
    uint256 _vestingDurationInSeconds) 
    external pure returns(bytes memory) {
        require(_fundriser != address(0), FundriserNotBeZeroAddress());
        require(_goalInEth > 0,GoalShouldThanZero());
        require(_vestingDurationInSeconds > 0,VestingDurationShouldThanZero());
        return abi.encode(_fundriser,_owner,_goalInEth,_vestingDurationInSeconds);
    }

    // геттеры

    function getFundriser() external view returns(address) {
        return fundriser;
    }

    function getGoal() external view returns(uint256) {
        return goalInEth;
    }

    function getTempMoneyAmount() external view returns(uint256) {
        return tempMoneyAmount;
    }
    
    function getAddressVestingContract() OnlyOnwerOrFundriser external view returns(address) {
        return address(vestingContract);
    }

    function getInvestor(address _investor) external view returns(uint256) {
        return investors[_investor];
    }

    function getVestingDurationSeconds() external view returns(uint256) {
        return vestingDurationInSeconds;
    }


}
