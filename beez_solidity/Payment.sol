//결제 : transfer로 원화, 비즈 교환 
//      구매페이백(원화로만 결제했을 경우 - 원화코인 1.0 %를 비즈로 전달)
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BeezToken.sol";
import "./WonToken.sol";

contract Payment {
    
    WonToken wonTokenAddr;
    BeezToken bzTokenAddr;
    
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
    

/******************************************************************************************************************/
/*************************************사용자, 소상공인 Main 출력 함수*********************************************/
    //매달 변경될때, aws람다를 사용해 백앤드에 요청을 보낸다. 요청받은 백앤드는 현재 시간(UNIX시간)을 setMonth에 입력 
    function getMonth() public view returns (uint256 getMonthWon, uint256 getMonthBz) {
        getMonthWon = wonTokenAddr.getMonth();
        getMonthBz = bzTokenAddr.getMonth();
    }
    
    //토큰CA를 한번만 setting하기 
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
/*************************************사용자, 소상공인 Main 출력 함수*********************************************/

// (사용자는 영수증을 검색하고(결제내역확인), 영수증에 리뷰가 작성 되어 있는지 파악.
// 	    => vue단에서 확인)
// (소상공인은 영수증을 검색하고(결제내역확인), 결제 내역 출력.
// 	    => 리뷰가 존재하면 리뷰 출력, 없으면 결제 내역만 출력)

    //receipt creation 결제(영수증 생성)
    //결제 내역 로딩용 영수증 
    function createReceipt(uint _visitTime, address _visitor, address _recipient, uint _cost,  uint _wonTokenCount, uint _bzTokenCount, uint _value1, uint _value2 , uint _value3) internal {
    // history에저장할떄 receipt가아니라 hash값을 넣는다. 검색기준을 receipt가아니라 hash로 해서 크기를 줄일 수있음
 
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
       
        shopHistory[_recipient].push(receiptHash); //소상공인용 리뷰 찾는 매핑
        visitorHistory[_visitor].push(receiptHash); //방문자용 리뷰 찾는 매핑
        receipts[receiptHash] = rc;
    
    }
    
    //receipt creation 결제(영수증 생성2)
    function payment(address _visitor, address _recipient, uint128 _cost, uint128 _wonAmount, 
    uint128 _bzAmount, uint256 _date) public costCheck(_cost, _wonAmount,_bzAmount) returns(uint8){
        require(wonTokenAddr.balance(_visitor) >= _wonAmount);
        require(bzTokenAddr.balance(_visitor) >= _bzAmount);
        wonTokenAddr.payment(_visitor, _recipient, _wonAmount, _date);
        bzTokenAddr.payment(_visitor, _recipient, _bzAmount, _date);
        //bzTokenAddr.Payback(_visitor, _wonAmount, _date);
        
        //시스템이 이벤트를 watch하다가 catch해서 bzTokenAddr.charge(sender, _wonAmount);를 실행시킨다.

        emit bzTokenPayback(true, _visitor, _recipient, _wonAmount, _bzAmount);
        
        uint visitTime = block.timestamp;
        uint _value1=0;
        uint _value2=0;
        uint _value3=0;
        
        createReceipt(visitTime, _visitor,_recipient, _cost,_wonAmount,_bzAmount, _value1, _value2, _value3); //영수증 생성
        
        return uint8(1);
    }

    //사용자 영수증(리뷰) 조회
    function getReviewForVisitor(address _visitor) public view returns(Receipt[] memory){
        Receipt[] memory result = new Receipt[]( visitorHistory[ _visitor ].length );
       
       
        for(uint i=0; i < visitorHistory[ _visitor ].length; i++){
            bytes32 receiptHash = visitorHistory[ _visitor ][i];
            Receipt memory rc = receipts[ receiptHash ];
            result[i] = rc;
        }
        
        return result;

      }
      
    //소상공인 영수증(리뷰) 조회
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
        
        bytes32 receiptHash = visitorHistory[_visitor][_receiptIndex]; // 해당 인덱스 값을 가진 byte를 찾아와서 receiptHash에 대입
        Receipt memory rc = receipts[receiptHash];//해당 byte를 가진 receipt를 rc에 대입
        rc.value1 = value1;  //해당 rc의 value1값을 수정
        rc.value2 = value2;  //해당 rc의 value2값을 수정
        rc.value3 = value3;  //해당 rc의 value3값을 수정
        receipts[receiptHash]= rc;
        
    }
    
/******************************************************************************************************************/
/*************************************사용자, 소상공인 Main 출력 함수*********************************************/

    //사용자 메인 화면 출력
    function userMainLoad() public
    view returns(uint256 canUseWon ,uint256 monthChargeWon,uint256 monthIncentiveWon,uint256 monthBeez,uint256 canUseBeez){
        canUseWon = wonTokenAddr.balance(msg.sender);                   //사용가능 금액
        monthChargeWon = wonTokenAddr.balanceWonOfMon();      //이달의 충전금액
        monthIncentiveWon = wonTokenAddr.balanceIncOfMon();   //이달의 인센티브
        monthBeez =  bzTokenAddr.balanceBeezOfMon(msg.sender);          //이달의 BEEZ
        canUseBeez = bzTokenAddr.balance(msg.sender);                   //사용가능 BEEZ
    }
    
    //소상공인 메인 화면 출력
    function recipientMainLoad(address _recipient) public view returns(uint256 wonIncome,uint256 exChangeWon,uint256 bzIncome,
    uint256 exChangeBz){
        // won.balanceOfWon[_recipient] + won.balanceWonOfMon[_store]; 총매출은 프론트 단에서 처리해야 할듯
        wonIncome = wonTokenAddr.balanceWonOfMon();   //이번달 원매출
        exChangeWon = wonTokenAddr.balance(_recipient);         //출금가능현금
        bzIncome = bzTokenAddr.balanceBeezOfMon(_recipient);    //이번달 비즈매출
        exChangeBz = bzTokenAddr.balance(_recipient);           //출금가능 비즈
    }
    
/******************************************************************************************************************/
    
    //나중에 삭제
    // beez balance check 사용가능 bz 체크
    function beezBalance() public view returns (uint256){
        return bzTokenAddr.balance(msg.sender);
    }
    //나중에 삭제
    //won balance check 사용가능 WON체크
    function wonBalance(address _to) public view returns (uint256){
        return wonTokenAddr.balance(_to);
    }
}
    