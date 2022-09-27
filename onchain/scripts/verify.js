// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const BigNumber = require('bignumber.js');

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const Verifier = await hre.ethers.getContractFactory("CKVerifier");
  const verifier = await Verifier.deploy(2, 1000, 1);

  await verifier.deployed();

  console.log("Verifer deployed to:", verifier.address);

  ax = ethers.BigNumber.from("89565891926547004231252920425935692360644145829622209833684329913297188986597"); // 2G
  ay = ethers.BigNumber.from("12158399299693830322967808612713398636155367887041628176798871954788371653930");
  pkx = ethers.BigNumber.from("112711660439710606056748659173929673102114977341539408544630613555209775888121"); // 3G
  pky = ethers.BigNumber.from("25583027980570883691656905877401976406448868254816295069919888960541586679410");

  await verifier.register_job([ax], [ay], pkx, pky);
  
  const randomness = 10;
  start_block = await verifier.init_challenge(1);
  //challenge = 0x5f112a25806694ac59cc10a9674b04cace29f2487ef2cf0441303f14b48946d6 from hashing
  // group order = 115792089237316195423570985008687907852837564279074904382605163141518161494337
  //response = (3*challenge  + 2) % group order
  response = ethers.BigNumber.from("13208054462378716353836018817465374182937102629100531704803268528485859431235")
  nonce1 = 58
  nonce2 = 100
  result = await verifier.wouldVerify(1, nonce1, nonce2, response, randomness);
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
