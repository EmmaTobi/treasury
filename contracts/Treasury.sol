// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Strategy.sol";

contract Treasury is Ownable, ReentrancyGuard {
    IStrategy strategy;

    event FundsDeposited(address indexed from, uint256 amount);
    event ReceivedNativeCoin(address indexed to, uint256 amount);

    /**
     * @dev Constructor to initialize the Treasury contract.
     * @param _strategy The address of the associated Strategy contract.
     */
    constructor(address _strategy) Ownable(msg.sender) {
        strategy = IStrategy(_strategy);
    }

    /**
     * @dev Deposit funds into the Treasury.
     * @param _token The address of the token to be deposited.
     * @param _amount The amount of tokens to be deposited.
     */
    function deposit(address _token, uint256 _amount) external nonReentrant {
        uint256 beforeBal = IERC20(_token).balanceOf(address(strategy));
        IERC20(_token).transferFrom(msg.sender, address(strategy), _amount);
        uint256 afterBal = IERC20(_token).balanceOf(address(strategy));
        strategy.deposit(_token, afterBal - beforeBal);

        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @dev Withdraw funds from the Treasury.
     * @param _amount The amount of tokens to be withdrawn.
     */
    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Withdrawal amount must be greater than zero");

        strategy.withdraw(_amount);
    }

    /**
     * @dev Calculate the aggregated percentage yield across all protocols in the associated Strategy.
     * @return The total aggregated percentage yield.
     */
    function calculateAggregatedPercentageYield() public view returns (uint256) {
        return strategy.calculateAggregatedPercentageYield();
    }

    /**
     * @dev Receive native coins.
     */
    receive() external payable {
        emit ReceivedNativeCoin(msg.sender, msg.value);
    }
}
