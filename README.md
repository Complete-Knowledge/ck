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

To lint Javascript scripts and tests, run
```
npm run lint
# Fix some linting errors automatically
npm run lint -- --fix
```

To run smart contract test cases, run
```
npx hardhat test
```

### Bitcoin Block Verification
To test out the Bitcoin block verification tools, run
```shell
npx hardhat run scripts/blocksynth.js --network hardhat
```

### Mainnet learnings
takes about 10 seconds between firing the transaction and it returning the receipt

fire the initChallenge transaction 18 seconds after the asic outputs its last warming up message, takes around 40-42 seconds between this message and the asic expecting the work (if it doesnt see work it sleeps for 15-20 seconds)

pool software outputs commitments and pub keys, waits for a randomness file to exist (created by the initchallenge script) and then the pool software broadcasts the work to the asic (after it is ready to work)
