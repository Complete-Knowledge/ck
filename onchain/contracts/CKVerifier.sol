//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "hardhat/console.sol";
import "elliptic-curve-solidity/contracts/EllipticCurve.sol";


contract CKVerifier {

  uint256 public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint256 public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
  uint256 public constant AA = 0;
  uint256 public constant BB = 7;
  uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
  uint256 public  difficulty;
  uint256 public time_threshold;
  uint256 public curr_job = 0;

  mapping (uint256 => uint256) commitments; // job id to commitment
  mapping (uint256 => uint256) random_inputs; // job id to trusted random input\
  mapping (uint256 => uint) pub_keys;
  mapping (uint256 => uint256) start_blocks;

  constructor(uint256 _d, uint256 _tau) public {
    difficulty = _d;
    time_threshold = _tau;
  }
  
  function register_job(uint256 _commitment, uint256 _pub_key) public returns(uint256) {
    commitments[curr_job] = _commitment;
    pub_keys[curr_job] = _pub_key;
    curr_job += 1;
    return curr_job - 1;
  }

  function init_challenge(uint256 _randomness, uint256 _job_id) public returns(uint256) {
    random_inputs[_job_id] = _randomness;
    uint256 block_number = block.number;
    start_blocks[_job_id] = block_number;
    return block_number;
  }

  function puz_accept(bytes32 data_hash) private returns(bool) {
    return true; // TODO
  }

  function zk_accept(uint commitment, uint challenge, uint response, uint pub_key) private returns(bool) {
    return true; //TODO
  }

  function verify(uint256 _job_id, uint256 nonce1, uint256 nonce2, uint256 response) public returns (bool) {
    uint commitment = commitments[_job_id];
    uint pub_key = pub_keys[_job_id];
    uint random_input = random_inputs[_job_id];
    bytes32 challenge = sha256(abi.encode(random_input, nonce2));
    if (block.number - start_blocks[_job_id] > time_threshold) {
      return false;
    }
    bytes32 data_hash = sha256(abi.encode(commitment, challenge, response, nonce1, nonce2));
    if (!puz_accept(data_hash)) {
      return false;
    }
    return zk_accept(commitment, uint(challenge), response, pub_key);
  }

  function derivePubKey(uint256 privKey) public pure returns(uint256 qx, uint256 qy) {
    (qx, qy) = EllipticCurve.ecMul(
      privKey,
      GX,
      GY,
      AA,
      PP
    );
  }
}

// contract Greeter {
//     string private greeting;



//     function greet() public view returns (string memory) {
//         return greeting;
//     }

//     function setGreeting(string memory _greeting) public {
//         console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
//         greeting = _greeting;
//     }
// }

