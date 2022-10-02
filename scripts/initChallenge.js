const hre = require("hardhat");
const BigNumber = require('bignumber.js');
fs = require('fs')

async function main() {

  contract_address = "0xE6E340D132b5f46d1e472DebcD681B2aBc16e57E"
  job_id = 1

  const MyContract = await ethers.getContractFactory("CKVerifier");
  const contract = await MyContract.attach(contract_address);

  challenge_tx = await contract.initChallenge(job_id, {gasLimit: 1000000});


// Now you can call functions of the contract
const receipt = await challenge_tx.wait()
console.log(receipt)
console.log(receipt.logs[0])
// Receipt should now contain the logs
randomness = receipt.logs[0]['topics'][2].slice(2)
console.log(randomness)
fs.writeFileSync('randomness.txt', randomness);
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
