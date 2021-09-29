//결제 : transfer로 원화, 비즈 교환 
//      구매페이백(원화로만 결제했을 경우 - 원화코인 1.0 %를 비즈로 전달)
//

pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BeezToken.sol";
import "./WonToken.sol";
import "./review.sol";

contract Payment {
    
bool payBackButtonOn=true;

    struct Receipt{
        
        uint visitTime;
        address visitor;
        address recipient;  
        uint cost;
        uint wonTokenCount;
        uint bzTokenCount;
        bool payBackButtonOn;   //페이백 지불여부 버튼 


        
    }
    
    

    // mapping (address=>mapping(address=>bytes32[]))history;
    mapping (address=>bytes32[]) public shopHistory;
    mapping (address=>bytes32[]) public visitorHistory;
    mapping (bytes32 => Receipt) public receipts;
    
    modifier costCheck(uint cost, uint wonTokenCount, uint bzTokenCount){
        require(cost == (wonTokenCount + bzTokenCount));
        _;
    }
    

    event bzTokenPayback(bool result,address sender, address recipient, uint128 wonAmount, uint128 bzAmount);
    
    
    //결제 내역 로딩용 영수증 
    function createReceipt(uint _visitTime, address _visitor, address _shopId, uint _cost,  uint _wonTokenCount, uint _bzTokenCount, bool _payBackButtonOn) internal {
    // history에저장할떄 receipt가아니라 hash값을 넣는다. 검색기준을 receipt가아니라 hash로 해서 크기를 줄일 수있음
    // bytes32 receiptHash;
    Receipt memory rc = Receipt(
        _visitTime,
        _visitor,
        _shopId,
        _cost,
        _wonTokenCount,
        _bzTokenCount,
        _payBackButtonOn
        );
    
    bytes32 receiptHash = keccak256(abi.encode(rc.visitTime, rc.visitor, rc.recipient, rc.cost,rc.wonTokenCount,rc.bzTokenCount,rc.payBackButtonOn));
   
    shopHistory[_shopId].push(receiptHash); //소상공인용 리뷰 찾는 매핑
    visitorHistory[_visitor].push(receiptHash); //방문자용 리뷰 찾는 매핑
    receipts[receiptHash] = rc;
    
    }
    
    // BeezToken bz;
    function beezBalance(BeezToken bzTokenAddr, address _to) public view returns (uint256){
        return bzTokenAddr.balance(_to);
    }
    //사용가능 WON체크
    function wonBalance(WonToken wonTokenAddr, address _to) public view returns (uint256){
        return wonTokenAddr.balance(_to);
    }

    //결제 
    function payment(WonToken wonTokenAddr, BeezToken bzTokenAddr, address _visitor, address _recipient, uint128 _cost, uint128 _wonAmount, uint128 _bzAmount) public costCheck(_cost, _wonAmount,_bzAmount){
        
        uint visitTime = block.timestamp;
        
        require(wonTokenAddr.balance(_visitor) >= _wonAmount);
        require(bzTokenAddr.balance(_visitor) >= _bzAmount);
        wonTokenAddr.payment(_visitor, _recipient, _wonAmount);
        bzTokenAddr.payment(_visitor, _recipient, _bzAmount);
        bzTokenAddr.Payback(_visitor, _wonAmount);
        
        //시스템이 이벤트를 watch하다가 catch해서 bzTokenAddr.charge(sender, _wonAmount);를 실행시킨다.

        emit bzTokenPayback(true, _visitor, _recipient, _wonAmount, _bzAmount);
        
        createReceipt(visitTime, _visitor,_recipient, _cost,_wonAmount,_bzAmount,payBackButtonOn); //영수증 생성
        
        
    }
    
    function getReviewForVisitor(address _visitor) public view returns(Receipt[] memory){
        Receipt[] memory result = new Receipt[]( visitorHistory[ _visitor ].length );
       
       
        for( uint i=0; i < visitorHistory[ _visitor ].length; i++){
        bytes32 receiptHash = visitorHistory[ _visitor ][i];
        Receipt memory rc = receipts[ receiptHash ];
        result[i] = rc;
    }
        return result;

      }
      
      
    function getReviewForRecipient(address _recipient) public view returns(Receipt[] memory){
        Receipt[] memory result = new Receipt[](shopHistory[_recipient].length);
         
        for( uint i=0; i < shopHistory[_recipient].length; i++){
            bytes32 receiptHash = shopHistory[_recipient][i];
            Receipt memory rc = receipts[ receiptHash ];
            result[i] = rc;
    }
        return result;
    }
     
     
    function writeReview(address _visitor, uint8 value1, uint8 value2, uint8 value3) public {
    //        calldata는 수정불가능하고 비 영구적 영역
       
        keccak256(abi.encodePacked(visitorHistory[_visitor],value1,value2,value3));

             
    }
  }
    



    
