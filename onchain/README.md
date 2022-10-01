# CK

On chain verification of CK proof

Current status : Completed and tested the ASIC protocol (with 1 round)

Sample proof and test supplied using the following script:

```shell
npx hardhat compile
npx hardhat run scripts/verify.js --network hardhat
```

## Development
To lint the smart contracts, run
```
node ./node_modules/solhint/solhint.js './contracts/**/*.sol'
```

### Bitcoin Block Verification
To test out the Bitcoin block verification tools, run
```shell
npx hardhat run scripts/blocksynth.js --network hardhat
```
