// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

import "../contracts/Protocol.sol";

contract TestAAVEProtocol is IProtocol {
    function isLiquidityPool() external pure returns  (bool){
        return true;
    }

    function isDex() external pure returns (bool) {
        return false;
    }

    function calculatePercentageYield() external pure returns (uint256) {
        return 20;
    }

    function deposit(address _depositToken, uint256 _amount) external {

    }

    function withdraw(uint256 _amount) external {

    }
}

contract TestCurveProtocol is IProtocol {
    function isLiquidityPool() external pure returns  (bool){
        return false;
    }

    function isDex() external pure returns (bool) {
        return true;
    }

    function calculatePercentageYield() external pure returns (uint256) {
        return 40;
    }

    function deposit(address _depositToken, uint256 _amount) external {

    }

    function withdraw(uint256 _amount) external {

    }
}