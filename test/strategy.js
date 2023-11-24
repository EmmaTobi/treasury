const { expect } = require('chai');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

const Strategy = artifacts.require('Strategy');

contract('Strategy', (accounts) => {
  const [owner, user] = accounts;

  let tokenInstance = '';
  let strategyInstance = '';

  beforeEach(async () => {
    this.strategy = await Strategy.deployed();;
  });

  it('should allow the owner to deposit funds', async () => {
    const depositedToken = tokenInstance.address;
    const amount = new BN(100);

    // Mint some tokens for testing purposes
    await tokenInstance.mint(owner, amount, { from: owner });

    // Approve the Strategy contract to spend the deposited token
    await tokenInstance.approve(strategyInstance.address, amount, { from: owner });

    // Perform the deposit
    const receipt = await strategyInstance.deposit(depositedToken, amount, { from: owner });

    // Check the emitted event
    expectEvent(receipt, 'Deposit', {
      depositedToken,
      amount,
      owner,
    });
  });
});
