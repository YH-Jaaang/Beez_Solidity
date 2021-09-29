//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Payment.sol";

contract Review  {
    Payment payment;
    
    
    function writeReviewforVisitor(uint value1, uint value2, uint value3) public returns(bytes32){
    // keccak256(receiptHash + keccak256(value1,valu2,value3));    
    }
   
    
    // function getReview(address _shopId) public view returns(Receipt memory){
     
    // }
    
}