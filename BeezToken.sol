// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./Payment.sol";

contract BeezToken is AccessControlEnumerable, ERC20Burnable{
    
    constructor() ERC20('BEEZ', 'BEEZ') {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        //payment = Payment(msg.sender);
    }
    
    struct payback{
        uint256 lastPaybackDate;      //마지막 Payback날짜 체크
        //uint128 balance;            //인센티브 밸런스체크
        uint128 beezOfMonth;         //이번달 충전 금액  //maxWonCharge - wonOfMonth[address] : 이번달 충전가능금액(charge.vue에 출력)
    }
    
    uint256 month = 1630422000;   //매달 초기화(이달 1일을 나타냄)
    mapping (address => payback) paybackCheck;  //주소 넣어서 인센티브 구조체 가져오는 매핑                    //인센티브 비율
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    //Payment payment;
    
    function updateMonth(address _address) private {
        //금액 충전시 마지막으로 인센티브 충전된 날짜가 지난달인 경우 (block.timestamp >= month && =>이건 빼야됨)
        if(paybackCheck[_address].lastPaybackDate < month){
            paybackCheck[_address].beezOfMonth = 0;  //인센티브 밸런스 초기화(여기서 이번에 충전된 )
        }
        paybackCheck[_address].lastPaybackDate = block.timestamp; //최근 인센티브 충전된 날짜 현재시간으로 업데이트
    }
    
    //결제, 리뷰 페이백  external- 컨트랙트 바깥에서만 호출될 수 있고 컨트랙트 내의 다른 함수에서 호출 X(public과 동일)
    function Payback(address _to, uint128 _amount) external virtual  {
        updateMonth(_to);
        _mint(_to, _amount/100);
        paybackCheck[_to].beezOfMonth = paybackCheck[_to].beezOfMonth + _amount/100;
    }
    
    //보유 bz 확인
    function balance(address account) external view virtual returns(uint256) {
        return balanceOf(account);
    }
    
    
    //결제
    function payment(address _sender, address _recipient, uint256 _amount) public virtual returns (bool){
        _transfer(_sender, _recipient, _amount);
        return true;
    }
    
    //   //이달의 bz체크, 월 마다 리셋되야함
    function balanceBeezOfMon (address _account) external view returns (uint128) {
        if(paybackCheck[_account].lastPaybackDate < month){
            return 0;
        }
        else{
            return paybackCheck[_account].beezOfMonth;
        }
        
    }
    //매달 변경될때, aws람다를 사용해 백앤드에 요청을 보낸다. 요청받은 백앤드는 현재 시간(UNIX시간)을 setMonth에 입력 
    function setMonth(uint256 _month) public {
        month = _month;
    }
   
}