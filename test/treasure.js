const { BN, expect } = require('chai');
const { expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

const Treasury = artifacts.require('Treasury');
const MockStrategy = artifacts.require('MockStrategy'); 

contract('Treasury', (accounts) => {
  const [owner, user] = accounts;

  const usdtCA = ''; 

  beforeEach(async () => {
    this.mockStrategy = await MockStrategy.new({ from: owner });
    this.treasury = await Treasury.new(this.mockStrategy.address, { from: owner });
  });

  it('should allow users to deposit ERC20 tokens', async () => {
    const amount = new BN(100);

    await Token.approve(this.treasury.address, amount, { from: user });

    const receipt = await this.treasury.deposit(usdtCA, amount, { from: user });

    expectEvent(receipt, 'FundsDeposited', {
      from: user,
      amount,
    });

  });

  it('should not allow users to deposit ETH directly', async () => {
    const amount = new BN(1);

    await expectRevert(
      this.treasury.depositEth({ from: user, value: amount }),
      'Function can only be called with ERC20 tokens'
    );
  });

  it('should calculate aggregated yield', async () => {
    const result = await this.treasury.calculateAggregatedYield();

    expect(result).to.be.bignumber.gte(new BN(0));
  });

});
