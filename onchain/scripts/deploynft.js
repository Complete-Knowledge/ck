// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const ethers = require("ethers");
const BigNumber = ethers.BigNumber;

async function main() {
  const bsFactory = await hre.ethers.getContractFactory("AtomicNFT");
  // TODO: Create CKRegistry
  const bs = await bsFactory.deploy("0x0000000000000000000000000000000000000000");

  await bs.deployed();
  const receipt = await bs.deployTransaction.wait();
  console.log("Deployment cost:", receipt.gasUsed.toNumber());
  console.log("AtomicNFT deployed at " + bs.address);
  console.log("NFT name:", await bs.name(), "\tSymbol:", await bs.symbol());
  // TODO: Mint tokens
  // const tokenId = 0;
  // console.log("Token URI of token", tokenId + ":", await bs.tokenURI(tokenId));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
