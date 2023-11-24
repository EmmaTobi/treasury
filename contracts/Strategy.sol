// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Protocol.sol";

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IStrategy {
    /**
     * @dev Deposit funds into the strategy.
     * @param _depositedToken The address of the token to be deposited.
     * @param _amount The amount of tokens to be deposited.
     */
    function deposit(address _depositedToken, uint256 _amount) external;

    /**
     * @dev Withdraw funds from the strategy.
     * @param _amount The amount of tokens to be withdrawn.
     */
    function withdraw(uint256 _amount) external;

    /**
     * @dev Calculate the aggregated percentage yield across all protocols.
     * @return The total aggregated percentage yield.
     */
    function calculateAggregatedPercentageYield() external view returns (uint256);
}

contract Strategy is IStrategy, Ownable { 
    address public usdtCA;
    address public daiCA;
    uint256 public totalRatio;

    IProtocol[] public protocols; 
    mapping(address => uint256) public protocolDistributionRatioMap; 
    address public uniswapRouter;

    event ReceivedNativeCoin(address indexed to, uint256 amount);

    /**
     * @dev Constructor to initialize the Strategy contract.
     * @param _protocolAddresses Array of protocol addresses.
     * @param _ratios Array of distribution ratios corresponding to each protocol.
     * @param _uniswapRouter The address of the Uniswap V2 Router.
     */
    constructor(
        address[] memory _protocolAddresses,
        uint256[] memory _ratios,
        address _uniswapRouter
    ) Ownable(msg.sender) {
        require(_protocolAddresses.length == _ratios.length, "Invalid input arrays");
        require(_protocolAddresses.length > 0, "You must provide at least one implementation of a protocol");

        uniswapRouter = _uniswapRouter;

        protocols = new IProtocol[](_protocolAddresses.length);

        totalRatio = 0;

        for (uint256 i = 0; i < _protocolAddresses.length; i++) {
            protocols.push(IProtocol(_protocolAddresses[i]));
            totalRatio += _ratios[i];
            protocolDistributionRatioMap[_protocolAddresses[i]] = _ratios[i];
        }

        require(totalRatio <= 100, "Total distribution ratio exceeds 100");
    }

    /**
     * @dev Set the distribution ratio for a specific protocol.
     * @param _protocol The address of the protocol.
     * @param _ratio The distribution ratio for the protocol.
     */
    function setProtocolDistributionRatio(address _protocol, uint256 _ratio) external onlyOwner {
        require(_protocol != address(0), "Invalid protocol address");
        require(_ratio <= 100, "Invalid ratio, must be <= 100");

        uint256 currentTotalRatio = totalRatio - protocolDistributionRatioMap[_protocol] + _ratio;

        require(currentTotalRatio <= 100, "Total ratio exceeds 100");

        protocolDistributionRatioMap[_protocol] = _ratio;
        totalRatio = currentTotalRatio;
    }

    /**
     * @dev Deposit funds into the strategy.
     * @param _depositedToken The address of the token to be deposited.
     * @param _amount The amount of tokens to be deposited.
     */
    function deposit(address _depositedToken, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Deposit amount must be greater than zero");

        distributeDeposit(_depositedToken, _amount);
    }

    /**
     * @dev Withdraw funds from the strategy.
     * @param _amount The amount of tokens to be withdrawn.
     */
    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Withdrawal amount must be greater than zero");

        distributeWithdraw(_amount);
    }

    /**
     * @dev Distribute the withdrawal across all protocols.
     * @param _amount The total withdrawal amount.
     */
    function distributeWithdraw(uint256 _amount) internal {
        require(protocols.length > 0, "No protocols available");

        for (uint256 i = 0; i < protocols.length; i++) {
            address protocolAddress = address(protocols[i]);
            uint256 ratio = protocolDistributionRatioMap[protocolAddress];
            uint256 protocolWithdrawAmount = (_amount * ratio) / 100;

            protocols[i].withdraw(protocolWithdrawAmount);
        }
    }

    /**
     * @dev Distribute the deposit across all protocols.
     * @param _depositedToken The address of the token being deposited.
     * @param _amount The total deposit amount.
     */
    function distributeDeposit(address _depositedToken, uint256 _amount) internal {
        require(protocols.length > 0, "No protocols available");

        for (uint256 i = 0; i < protocols.length; i++) {
            address protocolAddress = address(protocols[i]);
            uint256 ratio = protocolDistributionRatioMap[protocolAddress];
            uint256 protocolDepositAmount = (_amount * ratio) / 100;

            if (protocols[i].isDex()) {
                swapToUsdt(_depositedToken, protocolDepositAmount);
                IERC20(usdtCA).approve(address(protocols[i]), protocolDepositAmount);

                protocols[i].deposit(usdtCA, protocolDepositAmount);
            } else if (protocols[i].isLiquidityPool()) {
                swapToDai(_depositedToken, protocolDepositAmount);
                IERC20(daiCA).approve(address(protocols[i]), protocolDepositAmount);

                protocols[i].deposit(daiCA, protocolDepositAmount);
            }
        }
    }

    /**
     * @dev Calculate the aggregated percentage yield across all protocols.
     * @return The total aggregated percentage yield.
     */
    function calculateAggregatedPercentageYield() public view returns (uint256) {
        require(protocols.length > 0, "No protocols available");

        uint256 totalYield = 0;

        for (uint256 i = 0; i < protocols.length; i++) {
            totalYield += protocols[i].calculatePercentageYield();
        }

        return totalYield;
    }

    /**
     * @dev Swap tokens to USDT.
     * @param _depositedToken The address of the token to be swapped.
     * @param _amount The amount of tokens to be swapped.
     */
    function swapToUsdt(address _depositedToken, uint256 _amount) internal {
        swapExactTokensForTokens(usdtCA, _depositedToken, _amount);
    }

    /**
     * @dev Swap tokens to DAI.
     * @param _depositedToken The address of the token to be swapped.
     * @param _amount The amount of tokens to be swapped.
     */
    function swapToDai(address _depositedToken, uint256 _amount) internal {
        swapExactTokensForTokens(daiCA, _depositedToken, _amount);
    }

    /**
     * @dev Execute an exact token swap using Uniswap V2 Router.
     * @param _outputTokenCa The address of the output token.
     * @param _depositedToken The address of the token to be swapped.
     * @param _amount The amount of tokens to be swapped.
     */
    function swapExactTokensForTokens(address _outputTokenCa, address _depositedToken, uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = _depositedToken;
        path[1] = _outputTokenCa;

        // Approve Uniswap Router to spend deposited token
        IERC20(_depositedToken).approve(address(uniswapRouter), _amount);

        // Swap deposited token 
        IUniswapV2Router(uniswapRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev Receive native coins.
     */
    receive() external payable {
        emit ReceivedNativeCoin(msg.sender, msg.value);
    }
}
