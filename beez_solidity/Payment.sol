//결제 : transfer로 원화, 비즈 교환 
//      구매페이백(원화로만 결제했을 경우 - 원화코인 1.0 %를 비즈로 전달)
//

pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BeezToken.sol";
import "./WonToken.sol";

contract Payment {

bool payBackButtonOn=true;   //상태변수 (기본 저장위치는 스토리지라서 파일에 저장)

    // -----------------------------------------------struct-----------------------------------------------

    struct Receipt{
        
        uint visitTime;
        address visitor;
        address recipient;  
        uint cost;
        uint wonTokenCount;
        uint bzTokenCount;  
        uint value1;
        uint value2;
        uint value3;

    
    }
    
    
    

    // -----------------------------------------------mapping---------------------------------------

    mapping (address=>bytes32[]) public shopHistory;
    mapping (address=>bytes32[]) public visitorHistory;
    mapping (bytes32 => Receipt) public receipts;
    
    
    // -----------------------------------------------modifier-----------------------------------------------

    modifier costCheck(uint cost, uint wonTokenCount, uint bzTokenCount){
        require(cost == (wonTokenCount + bzTokenCount));
        _;
    }
    

    // -----------------------------------------------event-----------------------------------------------
    event bzTokenPayback(bool result,address sender, address recipient, uint128 wonAmount, uint128 bzAmount);
    
    
    // -----------------------------------------------function-----------------------------------------------
    //결제 내역 로딩용 영수증 
    function createReceipt(uint _visitTime, address _visitor, address _recipient, uint _cost,  uint _wonTokenCount, uint _bzTokenCount, uint _value1, uint _value2 , uint _value3) internal {
    // history에저장할떄 receipt가아니라 hash값을 넣는다. 검색기준을 receipt가아니라 hash로 해서 크기를 줄일 수있음
    // bytes32 receiptHash;
    // payBackButtonOn= true;

    Receipt memory rc = Receipt(
        _visitTime,
        _visitor,
        _recipient,
        _cost,
        _wonTokenCount,
        _bzTokenCount,
        _value1,
        _value2,
        _value3
        );
    
    bytes32 receiptHash = keccak256(abi.encode(rc.visitTime, rc.visitor, rc.recipient, rc.cost,rc.wonTokenCount,rc.bzTokenCount,rc.value1,rc.value2,rc.value3));
   
    // history[_visitor].push(receiptHash);
    // history[_shopId].push(receiptHash);
    shopHistory[_recipient].push(receiptHash); //소상공인용 리뷰 찾는 매핑
    visitorHistory[_visitor].push(receiptHash); //방문자용 리뷰 찾는 매핑
    receipts[receiptHash] = rc;
    
    }
    
    /******************************************************************************************************************/
    //매달 변경될때, aws람다를 사용해 백앤드에 요청을 보낸다. 요청받은 백앤드는 현재 시간(UNIX시간)을 setMonth에 입력 
    function setMonth(uint256 _date) public {
        wonTokenAddr.setMonth(_date);
        bzTokenAddr.setMonth(_date);
    }
    
    //토큰CA를 한번만 setting하기 
    WonToken wonTokenAddr;
    BeezToken bzTokenAddr;
    function setTokenCA(WonToken _wonTokenAddr, BeezToken _bzTokenAddr) public {
        wonTokenAddr = _wonTokenAddr;
        bzTokenAddr = _bzTokenAddr;
    }
    
    //wonToken : mint(생성), beezToken : burn(소멸)   //시스템이 해야될 일
    function exchange(address _to, uint256 _amount) public {
        wonTokenAddr.charge(_to, _amount);
        bzTokenAddr.exchange(_to, _amount);
    }
    
    /******************************************************************************************************************/
    
    // beez balance check 사용가능 bz 체크
    function beezBalance(address _to) public view returns (uint256){
        return bzTokenAddr.balance(_to);
    }
    //won balance check 사용가능 WON체크
    function wonBalance(address _to) public view returns (uint256){
        return wonTokenAddr.balance(_to);
    }

    //receipt creation 결제(영수증 생성)
    function payment(address _visitor, address _recipient, uint128 _cost, uint128 _wonAmount, 
    uint128 _bzAmount, uint256 _date) public costCheck(_cost, _wonAmount,_bzAmount){
        
        uint visitTime = block.timestamp;
        uint _value1=0;
        uint _value2=0;
        uint _value3=0;
        require(wonTokenAddr.balance(_visitor) >= _wonAmount);
        require(bzTokenAddr.balance(_visitor) >= _bzAmount);
        wonTokenAddr.payment(_visitor, _recipient, _wonAmount, _date);
        bzTokenAddr.payment(_visitor, _recipient, _bzAmount, _date);
        bzTokenAddr.Payback(_visitor, _wonAmount, _date);
        
        //시스템이 이벤트를 watch하다가 catch해서 bzTokenAddr.charge(sender, _wonAmount);를 실행시킨다.

        emit bzTokenPayback(true, _visitor, _recipient, _wonAmount, _bzAmount);
        
        createReceipt(visitTime, _visitor,_recipient, _cost,_wonAmount,_bzAmount, _value1, _value2, _value3); //영수증 생성
        
        
    }


 
 //review 리뷰 조회
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
     
//리뷰작성
    function writeReview(address _visitor, uint16 _receiptIndex,  uint8 value1, uint8 value2, uint8 value3) public {
    //
    bytes32 receiptHash = visitorHistory[_visitor][_receiptIndex]; // 해당 인덱스 값을 가진 byte를 찾아와서 receiptHash에 대입
    Receipt memory rc = receipts[receiptHash];//해당 byte를 가진 receipt를 rc에 대입
    rc.value1 = value1;  //해당 rc의 value1값을 수정
    rc.value2 = value2;  //해당 rc의 value2값을 수정
    rc.value3 = value3;  //해당 rc의 value3값을 수정
    receipts[receiptHash]= rc;
    // visitorHistory[_visitor][_receiptIndex] = keccak256(abi.encode(rc));
    // receipts[receiptHash]  = receipts[visitorHistory[_visitor][_receiptIndex]];
    // receiptHash=visitorHistory[_visitor][_receiptIndex];
    // visitorHistory[_visitor][_receiptIndex]= keccak256(abi.encode(receipts[receiptHash],value1,value2,value3));
    
    }
    
    
    
//main page load 
    function userMainLoad(address _account) public
    view returns(uint256 canUseWon ,uint256 monthChargeWon,uint256 monthIncentiveWon,uint256 monthBeez,uint256 canUseBeez){
         canUseWon = wonTokenAddr.balance(_account); //사용가능 금액
         monthChargeWon = wonTokenAddr.balanceWonOfMon(_account);     //이달의 충전금액
         monthIncentiveWon = wonTokenAddr.balanceIncOfMon(_account);   //이달의 인센티브
         monthBeez =  bzTokenAddr.balanceBeezOfMon(_account); //이달의 BEEZ
         canUseBeez = bzTokenAddr.balance(_account); //사용가능 BEEZ
    }
    
    
    
    function recipientMainLoad(address _recipient) public view returns(uint256 wonIncome,uint256 exChangeWon,uint256 bzIncome,
    uint256 exChangeBz){
        // won.balanceOfWon[_recipient] + won.balanceWonOfMon[_store]; 총매출은 프론트 단에서 처리해야 할듯
             wonIncome = wonTokenAddr.balanceWonOfMon(_recipient);
             exChangeWon = wonTokenAddr.balance(_recipient);
             bzIncome = bzTokenAddr.balanceBeezOfMon(_recipient);
             exChangeBz = bzTokenAddr.balance(_recipient);
          
    }
    
    
    
  }
    