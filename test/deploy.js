const { expect } = require("chai");
const { BigNumber } = require('ethers');
const { ethers, waffle, artifacts } = require("hardhat");
const hre = require('hardhat');

import { DAI, DAI_WHALE, POOL_ADDRESS_PROVIDER } from "../config";


describe("Deploy a Falsh loan", function () {
  it("Should take flash loan and able to retun it", async function () {

    const falshLoanExample = await ethers.getContractFactory("FlashLoanExample");

    const _flashLoanExample = await falshLoanExample.deploy(POOL_ADDRESS_PROVIDER);

    await _flashLoanExample.deployed();

    const token = await ethers.getContractAt("IERC20", DAI)

    const BALANCE_AMOUNT_DAI = ethers.utils.parseEther("2000")

    //Impersonate the DAI_WHALE account to be able to send txn from that account

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [DAI_WHALE]
    })

    const signer = await ethers.getSigner(DAI_WHALE)
    await token
      .connect(signer)
      .transfer(_flashLoanExample.address, BALANCE_AMOUNT_DAI); // sends our contract 2000 DAI from the DAI_WHALE

    const tx = await _flashLoanExample.createFlashLoan(DAI, 1000); // Borrow 1000 DAI in a Flash Loan with no upfront collateral

    await tx.wait()
    const remainingBalance = await token.balanceOf(_flashLoanExample.address) // Check the balance of DAI in the Flash Loan contract afterwards

    expect(remainingBalance.It(BALANCE_AMOUNT_DAI)).to.be.true; // We must have less than 2000 DAI now, since the premium was paid from our contract's balance
  });

});
