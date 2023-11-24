// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

interface IProtocol {

    function isLiquidityPool() external view returns  (bool);

    function isDex() external view returns (bool);

    function calculatePercentageYield() external view returns (uint256);

    function deposit(address _depositToken, uint256 _amount) external;

    function withdraw(uint256 _amount) external;
}

