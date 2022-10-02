
const hre = require("hardhat");
const BigNumber = require('bignumber.js');
const { version } = require("chai");
var fs = require('fs');

async function main() {
  // Randomness : 0x1979e6c1c8c27ca405b3ab85b2a5b758613fe3c8e67c67a198dc6ae28d5050d2 need to use this for the specific response

  const Verifier = await hre.ethers.getContractFactory("CKVerifier");
  const verifier = await Verifier.deploy(3026, 62, 5, 1);

  await verifier.deployed();

  contract_address = verifier.address;
  console.log("Verifer deployed to:", contract_address);

  var [commitmentsX,commitmentsY,pkx,pky] = [
    [
      '18473135073973899793522577085858960520395250054628647061504219196332411292913',
      '2223780137980010998289687545805943070025774957405014561067208186497456670559',
      '38598588033312200985846911311655612606740939535638875284020488954839956698240',
      '85691741588528078947490382220225873447504547836018002422679201115570768933612',
      '103404113196642613764264544068895795316486290839006735135792233254224446089710'
    ],
    [
      '52627447426174899695464087787118993839125562038437891359546002417431843852795',
      '81364585271914368753332156523747712081395709843989348272412924549826209249626',
      '71657897739406727459380162084502641630442136108621078979085419720658723148943',
      '43935343179138218144044749952732160365281005618517633883512066227624547133436',
      '109747945663080691532650320093561150848290902930375645983385250687212993684953'
    ],
    '61555156205734835139964493277968895515822792355257032700559544512788092514447',
    '42352591524506582366280373141491804577399703196304936933600912463157716854372'
  ]
  
  for (let i = 0; i < commitmentsX.length; i++) {
    commitmentsX[i] = ethers.BigNumber.from(commitmentsX[i])
    commitmentsY[i] = ethers.BigNumber.from(commitmentsY[i])
  }
  pkx = ethers.BigNumber.from(pkx)
  pky = ethers.BigNumber.from(pky)

  register_tx = await verifier.registerJob(commitmentsX, commitmentsY, pkx, pky, { gasLimit: 1000000 });
  const receipt1 = await register_tx.wait()
  console.log(receipt1.logs)
  
  
  
  job_id = 1
  // const randomness = '0x1979e6c1c8c27ca405b3ab85b2a5b758613fe3c8e67c67a198dc6ae28d5050d2'
  const challenge_tx = await verifier.initChallenge(job_id);

  const receipt2 = await challenge_tx.wait();
  console.log(receipt2.logs);


  
  const jsonString = fs.readFileSync("../result.json", "utf-8", "r")  

    const blocks = JSON.parse(jsonString)
    console.log(blocks)
  
      // Now you can call functions of the contract
      verify_tx = await verifier.verify(job_id, blocks, { gasLimit: 10000000 });
      const receipt3 = await verify_tx.wait()
    // Receipt should now contain the logs
      console.log(verify_tx)
      console.log(receipt3)
      console.log(receipt3.logs)
  }


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
