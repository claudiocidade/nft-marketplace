import { ethers } from "hardhat";

describe("nft-marketplace", function () {
  it("Should create NFT item", async function () {
    const MarketFactory = await ethers.getContractFactory("Market");
    const marketContract = await MarketFactory.deploy();
    await marketContract.deployed();

    const TokenFactory = await ethers.getContractFactory("NFT");
    const tokenContract = await TokenFactory.deploy(marketContract.address);
    await tokenContract.deployed();
    const teste = TokenFactory.attach(tokenContract.address);
   
    const listingFee = await teste.getListingFee();
    const price = ethers.utils.parseUnits('100', 'ether');
    console.log(price);
    // assert(listingFee);
  });
});
