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
  const verifier = await Verifier.deploy(1, 1000, 1);

  await verifier.deployed();

  console.log("Verifer deployed to:", verifier.address);

  pkx = ethers.BigNumber.from("96243806373204481945601038032046653703220698319981937285552484200780161929369");
  pky = ethers.BigNumber.from("38491887063126731616107561324549857553379482038905959648633452227158984216732");
  
  
  ax = ethers.BigNumber.from("69322316609532738029407580266198485199451988812403823163625810273619274439640");
  ay = ethers.BigNumber.from("13378712953394075803199026651505869426471977526372761219422905810209273267514");

  genTx0 = "0x01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff2f02d301044781376305";
  extraNonce1 = "0xdeadc0de";
  extraNonce2 = "0x48";
  genTx1 = "0x1c5c929ae2cb443d460be0d1663bdb35933cd6b226c02c9f5ef0b128dde7a34e4f00000000020000000000000000266a24aa21a9ede2f61c3f71d1defd3fa999dfa36953755c690689799962b48bebd836974e8cf900f2052a01000000160014475a44069a4288f3df3048fb12926f27c63f157900000000";
  nonce = "0x02570730";
  nbits = "0x1d00ffff"
  nTime = "0x633780f7"
  previousBlockHash = "0x000000000002ea8eb35b9df5a5f7d3f7182d5226e4e9ab5399fe7582f0f9a9de"
  nversion = "0x20000000"

  await verifier.register_job([ax], [ay], pkx, pky);
  
  const randomness = 10;
  start_block = await verifier.init_challenge(1);
  
  singleTxBitcoinBlock = [  genTx0, extraNonce1, extraNonce2, genTx1, nonce, nbits, nTime, previousBlockHash, nversion]

  result = await verifier.wouldVerify2(1,  [singleTxBitcoinBlock], randomness);
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
