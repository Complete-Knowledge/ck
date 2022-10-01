// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const BigNumber = require('bignumber.js');
const { version } = require("chai");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const Verifier = await hre.ethers.getContractFactory("CKVerifier");
  const verifier = await Verifier.deploy(1, 1000, 1, 4);

  await verifier.deployed();

  console.log("Verifer deployed to:", verifier.address);

  const pkx = ethers.BigNumber.from("96243806373204481945601038032046653703220698319981937285552484200780161929369");
  const pky = ethers.BigNumber.from("38491887063126731616107561324549857553379482038905959648633452227158984216732");

  //////////////////////////////////////////////////////////
  
  
  const ax = ethers.BigNumber.from("103752014574351234261897238474613553110705970509659950108250042593458514445317");
  const ay = ethers.BigNumber.from("56152132713981794557009406875925966805514519656492782080878459897883540312013");

  const genTx0 = "0x01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff2f02ed01045fa7376305";
  const extraNonce1 = "0xdeadc0de";
  const extraNonce2 = "0x72";
  const genTx1 = "0x8dd11b0ad47ae6501ef952276fdb1f8b92d0f94135f684afe27f91c30887d48e7600000000020000000000000000266a24aa21a9ede2f61c3f71d1defd3fa999dfa36953755c690689799962b48bebd836974e8cf900f2052a01000000160014475a44069a4288f3df3048fb12926f27c63f157900000000";
  const nonce = "0x8dccfb45";
  const nbits = "0x1d00ffff";
  const nTime = "0x6337a65c";
  const previousBlockHash = "0x00000000001212c516be901a6353d8f616639cd0f70776852cf7863b76c26436";
  const nversion = "0x20000000";

  await verifier.registerJob([ax], [ay], pkx, pky);
  
  const randomness = 14;
  const challenge_tx = await verifier.initChallenge(1);
  const receipt = await challenge_tx.wait();
  // Receipt should now contain the logs
  console.log(receipt.logs);
  
  const singleTxBitcoinBlock = [genTx0, extraNonce1, extraNonce2, genTx1, nonce, nbits, nTime, previousBlockHash, nversion];
  result = await verifier.verify(1, [singleTxBitcoinBlock]);
  console.log(result);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
