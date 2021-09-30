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

// BeezToken bz; //bz토큰 컨트랙트객체
// WonToken won;  //won토큰 컨트랙트객체

    struct Receipt{
        
        uint visitTime;
        address visitor;
        address recipient;  
        uint cost;
        uint wonTokenCount;
        uint bzTokenCount;  
        bool payBackButtonOn;
        // uint value1;
        // uint value2;
        // uint value3;

    
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
    payBackButtonOn= true;
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
   
    // history[_visitor].push(receiptHash);
    // history[_shopId].push(receiptHash);
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
    function payment(WonToken wonTokenAddr, BeezToken bzTokenAddr, address _visitor, address _recipient, uint128 _cost, uint128 _wonAmount, 
    uint128 _bzAmount, uint256 _date) public costCheck(_cost, _wonAmount,_bzAmount){
        
        uint visitTime = block.timestamp;
        
        require(wonTokenAddr.balance(_visitor) >= _wonAmount);
        require(bzTokenAddr.balance(_visitor) >= _bzAmount);
        wonTokenAddr.payment(_visitor, _recipient, _wonAmount, _date);
        bzTokenAddr.payment(_visitor, _recipient, _bzAmount, _date);
        bzTokenAddr.Payback(_visitor, _wonAmount, _date);
        
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
     
     
    function writeReview(address _visitor,Receipt[] memory rc, uint8 value1, uint8 value2, uint8 value3) public {
          

    }
    
    
    
    function userMainLoad(BeezToken bz,WonToken won, address _account) public
    view returns(uint256 canUseWon ,uint256 monthChargeWon,uint256 monthIncentiveWon,uint256 monthBeez,uint256 canUseBeez){
         canUseWon = won.balance(_account); //사용가능 금액
         monthChargeWon = won.balanceWonOfMon(_account);     //이달의 충전금액
         monthIncentiveWon =won.balanceIncOfMon(_account);   //이달의 인센티브
         monthBeez =  bz.balanceBeezOfMon(_account); //이달의 BEEZ
         canUseBeez = bz.balance(_account); //사용가능 BEEZ
    }
    
    
    
    function recipientMainLoad(BeezToken bz, WonToken won, address _recipient) public view returns(uint256 wonIncome,uint256 exChangeWon,uint256 bzIncome,
    uint256 exChangeBz){
        // won.balanceOfWon[_recipient] + won.balanceWonOfMon[_store]; 총매출은 프론트 단에서 처리해야 할듯
             wonIncome = won.balanceWonOfMon(_recipient);
             exChangeWon = won.balance(_recipient);
             bzIncome = bz.balanceBeezOfMon(_recipient);
             exChangeBz = bz.balance(_recipient);
          
    }
  }
    



    
