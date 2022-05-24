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

  mapping (uint => uint) commitmentsX; // job id to commitment
  mapping (uint => uint) commitmentsY; // job id to commitment
  mapping (uint => uint) randomness_inputs; // job id to trusted random input\
  mapping (uint => uint) pub_keysX;
  mapping (uint => uint) pub_keysY;
  mapping (uint => uint) start_blocks;

  constructor(uint _d, uint _tau) public {
    difficulty = _d;
    time_threshold = _tau;
  }
  
  function register_job(uint _aX, uint _aY, uint _pkX, uint _pkY) public returns(uint) {
    commitmentsX[curr_job] = _aX;
    commitmentsY[curr_job] = _aY;
    pub_keysX[curr_job] = _pkX;
    pub_keysY[curr_job] = _pkY;
    curr_job += 1;
    return curr_job - 1;
  }

  function init_challenge(uint _randomness, uint _job_id) public returns(uint) {
    randomness_inputs[_job_id] = _randomness;
    uint block_number = block.number;
    start_blocks[_job_id] = block_number;
    return block_number;
  }

  function puz_accept(bytes32 data_hash) private returns(bool) {
    return true; // TODO
  }

  function zk_accept(uint aX, uint aY, uint challenge, uint response, uint pkX, uint pkY) private pure returns(bool) {
    (uint gsX, uint gsY) = EllipticCurve.ecMul(response, GX, GY, AA, PP);
    (uint tempX, uint tempY) = EllipticCurve.ecMul(challenge, pkX, pkY, AA, PP);
    (uint rhsX, uint rhsY) = EllipticCurve.ecAdd(aX, aY, tempX, tempY, AA, PP);
    
    return (gsX == rhsX) && (gsY == rhsY);
  }

  function verify(uint _job_id, uint nonce1, uint nonce2, uint response) public returns (bool) {
    uint aX = commitmentsX[_job_id];
    uint aY = commitmentsY[_job_id];
    uint pkX = pub_keysX[_job_id];
    uint pkY = pub_keysY[_job_id];
    uint random_input = randomness_inputs[_job_id];
    bytes32 challenge = sha256(abi.encode(random_input, nonce2));
    if (block.number - start_blocks[_job_id] > time_threshold) {
      return false;
    }
    bytes32 data_hash = sha256(abi.encode(aX, aY, challenge, response, nonce1, nonce2));
    if (!puz_accept(data_hash)) {
      return false;
    }
    return zk_accept(aX, aY, uint(challenge), response, pkX, pkY);
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

