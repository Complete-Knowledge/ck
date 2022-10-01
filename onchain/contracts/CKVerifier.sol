//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./EllipticCurve.sol";
import "./BlockSynthesis.sol";

struct SingleTxBitcoinBlockSplit {
  bytes genTx0;
  bytes4 extraNonce1;
  bytes extraNonce2;
  
  // response is the first 32 bytes of genTx1
  bytes32 response;
  // remainingTx is the remaining bytes of genTx1
  bytes remainingTx;
  
  bytes4 nonce;
  bytes4 bits;
  bytes4 nTime;
  bytes32 previousBlockHash;
  bytes4 version;
}

contract CKVerifier is BlockSynthesis {

  uint public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
  uint public constant AA = 0;
  uint public constant BB = 7;
  uint public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
  uint public difficulty;
  uint public time_threshold;
  uint public curr_job = 0;
  uint public numberOfRounds;

  mapping (uint => uint[]) commitmentsX; // job id to commitment
  mapping (uint => uint[]) commitmentsY; // job id to commitment
  mapping (uint => uint) randomness_inputs; // job id to trusted random input
  mapping (uint => uint) pub_keysX;
  mapping (uint => uint) pub_keysY;
  mapping (uint => uint) start_times;
  mapping (address => bool) ck_addresses;
  
  event NewJob(uint indexed pubKeyX, uint indexed pubKeyY, uint indexed jobId);
  event ChallengeInitialized(uint indexed jobId , uint indexed randomness, uint indexed startTime);

  constructor(uint _d, uint _tau, uint nRounds) {
    difficulty = _d;
    time_threshold = _tau;
    numberOfRounds = nRounds;
  }
  
  function register_job(uint[] calldata _aX, uint[] calldata _aY, uint _pkX, uint _pkY) public returns(uint) {
    require(_aX.length == numberOfRounds);
    require(_aY.length == numberOfRounds);
    curr_job += 1;
    commitmentsX[curr_job] = _aX;
    commitmentsY[curr_job] = _aY;
    pub_keysX[curr_job] = _pkX;
    pub_keysY[curr_job] = _pkY;
    emit NewJob(_pkX, _pkY, curr_job);
    return curr_job;
  }

  function init_challenge(uint _job_id) public returns(uint) {
    require(start_times[_job_id] == 0, "Challenge already initialized");
    randomness_inputs[_job_id] = uint(keccak256(abi.encodePacked(_job_id, block.difficulty)));
    uint startTime = block.timestamp;
    start_times[_job_id] = startTime;
    emit ChallengeInitialized(_job_id, randomness_inputs[_job_id], startTime);
    return startTime;
  }

  function pow_accept(bytes32 data_hash) private view returns(bool) {
    if (difficulty == 0) return true;
    if (blockDifficulty(data_hash) >= difficulty) {
      return true;
    }
    return false;
    // return (uint(data_hash)) < (1 << (256 - difficulty));
  }

  function zk_accept(uint aX, uint aY, uint challenge, uint response, uint pkX, uint pkY) private pure returns(bool) {
    (uint gsX, uint gsY) = EllipticCurve.ecMul(response, GX, GY, AA, PP);
    (uint tempX, uint tempY) = EllipticCurve.ecMul(challenge, pkX, pkY, AA, PP);
    (uint rhsX, uint rhsY) = EllipticCurve.ecAdd(aX, aY, tempX, tempY, AA, PP);
    return (gsX == rhsX) && (gsY == rhsY);
  }
  
  function derive_address(uint _job_id) private view returns (address) {
    uint pkx = pub_keysX[_job_id];
    uint pky = pub_keysY[_job_id];
    return address(uint160(uint256(keccak256(bytes.concat(bytes32(pkx), bytes32(pky))))));
  }

  function verify(uint _job_id, SingleTxBitcoinBlock[] calldata blocks) public returns (bool) {
    uint random_input = randomness_inputs[_job_id];
    bool accepted = wouldVerify(_job_id, blocks, random_input); 
    if (accepted) {
      address addr = derive_address(_job_id);
      ck_addresses[addr] = true;
    }
    // Maybe emit Verify log for ease of use only
    return accepted;
  }
	
  // Bitcoin block struct containing everything
  // accept BitcoinBlock[] - numberOfRounds in length or more
  // [genTx0, genTx1, extraNonce1, extraNonce2] -> merkle hash, previousBlockHash, nonce, bits, nTime, version
  // Instead of genTx1: have response, and remaining tx as arguments
  //  	genTx1 = bytes.concat(response, remainingTx)
  
  function wouldVerify(uint _job_id, SingleTxBitcoinBlock[] calldata blocks, uint random_input) private view returns (bool) {
    require(blocks.length == numberOfRounds);
    if (block.timestamp - start_times[_job_id] > time_threshold) {
      return false;
    }
    // response = gentx1 (first 32 bytes)
    // bitcoin block hash
    for (uint i = 0; i < blocks.length; i++) {
	    bytes32 data_hash = blockHash(createSingleTxHeader(blocks[i]));
	    if (!pow_accept(data_hash)) {
	      return false;
	    }
    }
    // challenge can be determined by all arguments except the response (just hash all arguments together, including randomness - concat at end)
    for (uint i = 0; i < blocks.length; i++) {
      SingleTxBitcoinBlock calldata current_block  = blocks[i];
      bytes32 challenge_i = sha256(bytes.concat(current_block.version, current_block.previousBlockHash, current_block.genTx0, 
                                                current_block.extraNonce1, current_block.genTx1[32:], current_block.nTime,
                                                current_block.bits, bytes32(random_input + i)));

	    bytes32 response = bytes32(current_block.genTx1[:32]);
	    
	    uint aXi = commitmentsX[_job_id][i];
	    uint aYi = commitmentsY[_job_id][i];
	    uint pkX = pub_keysX[_job_id];
	    uint pkY = pub_keysY[_job_id];
	    if (!zk_accept(aXi, aYi, uint(challenge_i), uint(response), pkX, pkY)) {
	    	return false;
	    }
    }
    return true;
  }
}

