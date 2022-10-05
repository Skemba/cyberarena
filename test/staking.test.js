const { expect } = require("chai");

describe("TokenStaking", function () {
  let Token;
  let testToken;
  let TokenStaking;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  before(async function () {
    Token = await ethers.getContractFactory("Ca");
    TokenStaking = await ethers.getContractFactory("MockStaking");
  });
  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    testToken = await Token.deploy(5000000000, addr1.address, addr2.address);
    await testToken.deployed();
  });

  describe("Staking", function () {
    it("Should assign the total supply of tokens to the owner", async function () {
      const ownerBalance = await testToken.balanceOf(owner.address);
      expect(await testToken.totalSupply()).to.equal(ownerBalance);
    });

    it("Should stake and unstake less than 10 days", async function () {
      // deploy staking contract
      const tokenStaking = await TokenStaking.deploy(testToken.address, 10, 12*1e2, addr2.address);
      await tokenStaking.deployed();

      await testToken.addToTransferWhitelist([tokenStaking.address])
      let penDays = await tokenStaking.penaltyDays()
      expect(penDays).to.equal(10)

      const baseTime = 1622551248;
      const startTime = baseTime
      const duration = 432000; // 5 days

      tokenStaking.setCurrentTime(startTime)

      const ownerBalance = await testToken.balanceOf(owner.address);
      await testToken.approve(tokenStaking.address, ownerBalance)
      await tokenStaking.stake(1000000000)
      expect(await testToken.balanceOf(owner.address)).to.equal(4000000000);
      expect(await tokenStaking.totalShares()).to.equal(1000000000)

      const halfTime = startTime + duration / 2;
      await tokenStaking.setCurrentTime(halfTime);

      await tokenStaking.unstake();
      
      expect(await testToken.balanceOf(owner.address)).to.equal(4880000000);
      expect(await tokenStaking.totalShares()).to.equal(0)
    });

    it("Should stake and unstake more than 10 days", async function () {
      // deploy staking contract
      const tokenStaking = await TokenStaking.deploy(testToken.address, 10, 12*1e2, addr2.address);
      await tokenStaking.deployed();

      await testToken.addToTransferWhitelist([tokenStaking.address])
      let penDays = await tokenStaking.penaltyDays()
      expect(penDays).to.equal(10)

      const baseTime = 1622551248;
      const startTime = baseTime
      const duration = 63120000; // 24 months

      tokenStaking.setCurrentTime(startTime)

      const ownerBalance = await testToken.balanceOf(owner.address);
      await testToken.approve(tokenStaking.address, ownerBalance)
      await tokenStaking.stake(1000000000)
      expect(await testToken.balanceOf(owner.address)).to.equal(4000000000);
      expect(await tokenStaking.totalShares()).to.equal(1000000000)

      const halfTime = startTime + duration / 2;
      await tokenStaking.setCurrentTime(halfTime);

      await tokenStaking.unstake();
      expect(await testToken.balanceOf(owner.address)).to.equal(5000000000);
      expect(await tokenStaking.totalShares()).to.equal(0)
    });

    it("Should stake and unstake more than 10 days whitelisted", async function () {
      // whitelist owner for token transfers
      await testToken.addToTransferWhitelist([owner.address])
      expect(await testToken.isWhitelisted(owner.address)).to.equal(true)
      // deploy staking contract
      const tokenStaking = await TokenStaking.deploy(testToken.address, 10, 12*1e2, addr2.address);
      await tokenStaking.deployed();

      await testToken.addToTransferWhitelist([tokenStaking.address])
      let penDays = await tokenStaking.penaltyDays()
      expect(penDays).to.equal(10)

      const baseTime = 1622551248;
      const startTime = baseTime
      const duration = 63120000; // 24 months

      tokenStaking.setCurrentTime(startTime)

      const ownerBalance = await testToken.balanceOf(owner.address);
      await testToken.approve(tokenStaking.address, ownerBalance)
      await tokenStaking.stake(1000000000)
      expect(await testToken.balanceOf(owner.address)).to.equal(4000000000);
      expect(await tokenStaking.totalShares()).to.equal(1000000000)

      const halfTime = startTime + duration / 2;
      await tokenStaking.setCurrentTime(halfTime);

      await tokenStaking.unstake();
      expect(await testToken.balanceOf(owner.address)).to.equal(5000000000);
      expect(await tokenStaking.totalShares()).to.equal(0)
    });
});
});