//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "hardhat/console.sol";
import "elliptic-curve-solidity/contracts/EllipticCurve.sol";


contract CKVerifier {

  uint public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
  uint public constant AA = 0;
  uint public constant BB = 7;
  uint public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
  uint public  difficulty;
  uint public time_threshold;
  uint public curr_job = 0;
  uint public numberOfRounds;

  mapping (uint => uint[]) commitmentsX; // job id to commitment
  mapping (uint => uint[]) commitmentsY; // job id to commitment
  mapping (uint => uint) randomness_inputs; // job id to trusted random input\
  mapping (uint => uint) pub_keysX;
  mapping (uint => uint) pub_keysY;
  mapping (uint => uint) start_times;

  constructor(uint _d, uint _tau, uint nRounds) public {
    difficulty = _d;
    time_threshold = _tau;
    numberOfRounds = nRounds;
  }
  
  function register_job(uint _aX[], uint _aY[], uint _pkX, uint _pkY) public returns(uint) {
    require(_ax.length == numberOfRounds);
    require(_ay.length == numberOfRounds);
    curr_job += 1;
    commitmentsX[curr_job] = _aX;
    commitmentsY[curr_job] = _aY;
    pub_keysX[curr_job] = _pkX;
    pub_keysY[curr_job] = _pkY;
    emit JobRegistered(_pkX, _pkY, curr_job);
    return curr_job;
  }

  function init_challenge(uint _job_id, uint _randomness) public returns(uint) {
    randomness_inputs[_job_id] = keccak256(abi.encodePacked(_job_id, block.difficulty));
    emit NewChallenge(_job_id, randomness_inputs[_job_id]);
    uint block_timestamp = block.timestamp;
    start_times[_job_id] = block_timestamp;
    return block_timestamp;
  }

  function puz_accept(bytes32 data_hash) private view returns(bool) {
    if (difficulty == 0) return true;
    return (uint(data_hash)) < (1 << (256 - difficulty));
  }

  function zk_accept(uint aX, uint aY, uint challenge, uint response, uint pkX, uint pkY) private pure returns(bool) {
    (uint gsX, uint gsY) = EllipticCurve.ecMul(response, GX, GY, AA, PP);
    (uint tempX, uint tempY) = EllipticCurve.ecMul(challenge, pkX, pkY, AA, PP);
    (uint rhsX, uint rhsY) = EllipticCurve.ecAdd(aX, aY, tempX, tempY, AA, PP);
    return (gsX == rhsX) && (gsY == rhsY);
  }

  function verify(uint _job_id, uint nonce1, uint nonce2, uint response) public view returns (bool) {
    uint[] aX = commitmentsX[_job_id];
    uint[] aY = commitmentsY[_job_id];
    uint pkX = pub_keysX[_job_id];
    uint pkY = pub_keysY[_job_id];
    uint random_input = randomness_inputs[_job_id];
    bytes32 challenge = sha256(abi.encodePacked(nonce2, random_input));
    if (block.number - start_blocks[_job_id] > time_threshold) {
      return false;
    }
    bytes32 data_hash = sha256(abi.encode(aX, aY, challenge, response, nonce1, nonce2));
    if (!puz_accept(data_hash)) {
      return false;
    }
    return zk_accept(aX, aY, uint(challenge), response, pkX, pkY);
  }
	
  // Bitcoin block struct containing everything
  // accept BitcoinBlock[] - numberOfRounds in length or more
  // [genTx0, genTx1, extraNonce1, extraNonce2] -> merkle hash, previousBlockHash, nonce, bits, nTime, version
  // Instead of genTx1: have response, and remaining tx as arguments
  //  	genTx1 = bytes.concat(response, remainingTx)
  
  function verify2(uint _job_id, BitcoinBlock[] blocks) public view returns (bool) {
    require(blocks.length == numberOfRounds);
    uint random_input = randomness_inputs[_job_id];
    if (block.timestamp - start_times[_job_id] > time_threshold) {
      return false;
    }
    // response = gentx1 (first 32 bytes)
    // bitcoin block hash
    for (.. bitcoin blocks) {
	    bytes32 data_hash = sha256(abi.encode(form bitcoin header));
	    if (!puz_accept(data_hash)) {
	      return false;
	    }
    }
    // challenge can be determined by all arguments except the response (just hash all arguments together, including randomness - concat at end)
    for (i in ... bitcoin blocks) {
	    bytes32 challenge_i = sha256(abi.encodePacked(s1, s2, random_input + i));
	    uint aXi = commitmentsX[_job_id][i];
	    uint aYi = commitmentsY[_job_id][i];
	    uint pkX = pub_keysX[_job_id];
	    uint pkY = pub_keysY[_job_id];
	    return zk_accept(aXi, aYi, uint(challenge_i), response_i, pkX, pkY);
    }
    // Maybe emit Verify log for ease of use only
  }
}

