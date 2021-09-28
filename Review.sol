//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Review {
    
    struct Receipt{
        address visitor;
        address shopId;
        uint cost;
        uint wonTokenCount;
        uint bzTokenCount;
        
    }
    
    
    mapping (address=>mapping(address=>Receipt[]))history;
    mapping (address=>Receipt[])shopHistory;
    mapping (address=>Receipt[])visitorHistory;
    
    
    modifier costCheck(uint cost, uint wonTokenCount, uint bzTokenCount){
        require(cost == (wonTokenCount + bzTokenCount));
        _;
    }
    

    function writeReview(address visitor, address shopId, uint cost,  uint wonTokenCount, uint bzTokenCount) public costCheck(cost, wonTokenCount,bzTokenCount){
        
    Receipt memory rc = Receipt(
        visitor,
        shopId,
        cost,
        wonTokenCount,
        bzTokenCount
        
        );
    
    history[visitor][shopId].push(rc);
    shopHistory[shopId].push(rc);
    visitorHistory[visitor].push(rc);
    }

    function getReviewForShop(address shopId) public view returns(Receipt[] memory){
    return shopHistory[shopId];
   
    }
    
    function getReviewForCustomer(address visitor) public view returns(Receipt[] memory){
    return visitorHistory[visitor];
   
    }
    
    
    
}