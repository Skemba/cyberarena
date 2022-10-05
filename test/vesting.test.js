const { expect } = require("chai");

describe("TokenVesting", function () {
  let Token;
  let testToken;
  let TokenVesting;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  before(async function () {
    Token = await ethers.getContractFactory("Ca");
    TokenVesting = await ethers.getContractFactory("MockVesting");
  });
  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    testToken = await Token.deploy(5000000000, addr1.address, addr2.address);
    await testToken.deployed();
  });

  describe("Vesting", function () {
    it("Should assign the total supply of tokens to the owner", async function () {
      const ownerBalance = await testToken.balanceOf(owner.address);
      expect(await testToken.totalSupply()).to.equal(ownerBalance);
    });

    it("Should vest team tokens gradually", async function () {
      // deploy vesting contract
      const tokenVesting = await TokenVesting.deploy(testToken.address);
      await tokenVesting.deployed();
      expect((await tokenVesting.getToken()).toString()).to.equal(
        testToken.address
      );

      const ownerBalance = await testToken.balanceOf(owner.address);
      await testToken.approve(tokenVesting.address, ownerBalance)
      // send tokens to vesting contract
      await expect(testToken.transfer(tokenVesting.address, 1000000000))
        .to.emit(testToken, "Transfer")
        .withArgs(owner.address, tokenVesting.address, 990000000);
      const vestingContractBalance = await testToken.balanceOf(
        tokenVesting.address
      );
      const rewardsBalance = await testToken.balanceOf(
        addr1.address
      );
      const liquidityBalance = await testToken.balanceOf(
        addr2.address
      );
      expect(rewardsBalance).to.equal(5000000);
      expect(liquidityBalance).to.equal(2500000);
      expect(vestingContractBalance).to.equal(990000000);
      expect(await tokenVesting.getWithdrawableAmount()).to.equal(990000000);

      const baseTime = 1622551248;
      const beneficiary = addr1;
      const startTime = baseTime + 31560000; // 1 year
      const duration = 63120000; // 24 months
      const slicePeriodSeconds = 1;
      const amount = 990000000;

      tokenVesting.setCurrentTime(startTime)

      // create new vesting schedule
      await tokenVesting.createVestingSchedule(
        beneficiary.address,
        startTime,
        duration,
        slicePeriodSeconds,
        amount
      );

      // check that vested amount is 0
      expect(
        await tokenVesting.computeReleasableAmount(beneficiary.address)
      ).to.be.equal(0);

      // set time to half the vesting period
      const halfTime = startTime + duration / 2;
      await tokenVesting.setCurrentTime(halfTime);

      // check that vested amount is half the total amount to vest
      expect(
        await tokenVesting
          .connect(beneficiary)
          .computeReleasableAmount(beneficiary.address)
      ).to.be.equal(495000000);

      // check that only beneficiary can try to release vested tokens
      await expect(
        tokenVesting.connect(addr2).release(beneficiary.address, 100)
      ).to.be.revertedWith(
        "TokenVesting: only beneficiary and owner can release vested tokens"
      );

      // check that beneficiary cannot release more than the vested amount
      await expect(
        tokenVesting.connect(beneficiary).release(beneficiary.address, 990000000)
      ).to.be.revertedWith(
        "TokenVesting: cannot release tokens, not enough vested tokens"
      );

      // release 10 tokens and check that a Transfer event is emitted with a value of 10
      await expect(
        tokenVesting.connect(beneficiary).release(beneficiary.address, 10)
      )
        .to.emit(testToken, "Transfer")
        .withArgs(tokenVesting.address, beneficiary.address, 9);

      // check that the vested amount is now 494999990
      expect(
        await tokenVesting
          .connect(beneficiary)
          .computeReleasableAmount(beneficiary.address)
      ).to.be.equal(494999990);
      let vestingSchedule = await tokenVesting.getVestingSchedule(
        beneficiary.address
      );

      // check that the released amount is 10
      expect(vestingSchedule.released).to.be.equal(10);

      // set current time after the end of the vesting period
      await tokenVesting.setCurrentTime(startTime + duration + 1);

      // check that the vested amount is 999999990
      expect(
        await tokenVesting
          .connect(beneficiary)
          .computeReleasableAmount(beneficiary.address)
      ).to.be.equal(989999990);

      // beneficiary release vested tokens (499999995)
      await expect(
        tokenVesting.connect(beneficiary).release(beneficiary.address, 499999995)
      )
        .to.emit(testToken, "Transfer")
        .withArgs(tokenVesting.address, beneficiary.address, 494999995);

      // owner release vested tokens (499999995)
      await expect(tokenVesting.connect(owner).release(beneficiary.address, 489999995))
        .to.emit(testToken, "Transfer")
        .withArgs(tokenVesting.address, beneficiary.address, 485099995);
      vestingSchedule = await tokenVesting.getVestingSchedule(
        beneficiary.address
      );

      // check that the number of released tokens is 100
      expect(vestingSchedule.released).to.be.equal(990000000);

      // check that the vested amount is 0
      expect(
        await tokenVesting
          .connect(beneficiary)
          .computeReleasableAmount(beneficiary.address)
      ).to.be.equal(0);
    });

    it("Should check input parameters for createVestingSchedule method", async function () {
      const tokenVesting = await TokenVesting.deploy(testToken.address);
      await tokenVesting.deployed();
      await testToken.transfer(tokenVesting.address, 1000);
      const time = Date.now();
      await expect(
        tokenVesting.createVestingSchedule(
          addr1.address,
          time,
          0,
          1,
          1
        )
      ).to.be.revertedWith("TokenVesting: duration must be > 0");
      await expect(
        tokenVesting.createVestingSchedule(
          addr1.address,
          time,
          1,
          0,
          1
        )
      ).to.be.revertedWith("TokenVesting: slicePeriodSeconds must be >= 1");
      await expect(
        tokenVesting.createVestingSchedule(
          addr1.address,
          time,
          1,
          1,
          0
        )
      ).to.be.revertedWith("TokenVesting: amount must be > 0");
    });
  });
});