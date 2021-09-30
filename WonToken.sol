// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./BeezToken.sol";

contract WonToken is AccessControlEnumerable, ERC20Burnable{
    
    constructor() ERC20('WON', 'WON') {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }
    
    struct incentive{
        uint256 lastChargeDate;      //마지막 인센티브 충전 날짜 체크
        uint128 wonOfMonth;         //이번달 충전 금액  //maxWonCharge - wonOfMonth[address] : 이번달 충전가능금액(charge.vue에 출력)
        uint128 incentiveOfMonth;   //이번달 인센티브 금액  //maxIncentive - incentiveOfMonth[address] : 이번달 혜택가능금액(charge.vue에 출력)
    }

    uint256 month = 1630422000;   //매달 초기화(이달 1일을 나타냄)
    mapping (address => incentive) incentiveCheck;  //주소 넣어서 인센티브 구조체 가져오는 매핑
    uint128 incentiveRate;                          //인센티브 비율
    
    uint128 maxIncentive = 500000;  //한달 혜택가능금액
    uint128 maxWonCharge = 2000000; //한달 충전가능금액
    uint128 minWonCharge = 10000;   //충전은 10000원 이상
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    //충전결과 로그 
    event chargeResult(bool result, uint128 chargeAmount);
    
    //매달 초기화 함수
    function updateMonth(address _address, uint256 _date) private {
        //금액 충전시 마지막으로 인센티브 충전된 날짜가 지난달인 경우 (block.timestamp >= month && =>이건 빼야됨)
        if(incentiveCheck[_address].lastChargeDate < month){
            incentiveCheck[_address].wonOfMonth = 0;  //인센티브 밸런스 초기화(여기서 이번에 충전된 )
            incentiveCheck[_address].incentiveOfMonth = 0;
        }
        //(나중에 다시 block.timestamp으로 수정)
        incentiveCheck[_address].lastChargeDate = _date; //최근 인센티브 충전된 날짜 현재시간으로 업데이트
    }
    
    //충전
    function charge(address _to, uint256 _amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(_to, _amount);
    }
    function wowow(address _address) public view returns (uint256){
        return incentiveCheck[_address].lastChargeDate;
    }
    
    //인센티브 충전
    function incentiveCharge(address _to, uint128 _amount) internal virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        incentiveRate = _amount/10;
        _mint(_to, _amount + incentiveRate);
        incentiveCheck[_to].incentiveOfMonth += incentiveRate;
    }
    
    function chargeCheck(address _to, uint128  _amount, uint256 _date) public {
         //한달 최대 충전량
        updateMonth(_to, _date);    //require 전에 해줘야됨. 전달+지금충전하려는 금액이 2백이 넘으면 실행 불가.
        require(_amount >= minWonCharge);   // //최소충전금액 10000원을 넘어야 충전가능
        require(incentiveCheck[_to].wonOfMonth + _amount <= maxWonCharge); //최대충전금액 2000000원을 넘지않아야함
        //여기서 우리가 생각해야 되는게 30만원 충전시 인센티브 받고 21만원 충전 했을 경우 20만원은 인센티브 받고 1만원은 그냥 충전 **인센티브 붙는걸 생각 해야됨 => 완료
        
        incentiveCheck[_to].wonOfMonth += _amount;
        //이번달 충전금액(현재 충전할 금액을 더한)이 최대인센티브(50만원) 보다 작거나 같으면 인센티브 충전
        if(incentiveCheck[_to].wonOfMonth <= maxIncentive){
            incentiveCharge(_to, _amount);
        }else{
            //이번달 충전 금액(현재 충전금액을 뺀)이 최대 인센티브보다 적다
            if(incentiveCheck[_to].wonOfMonth - _amount <maxIncentive){
                charge(_to, incentiveCheck[_to].wonOfMonth - maxIncentive);
                incentiveCharge(_to, maxIncentive - (incentiveCheck[_to].wonOfMonth - _amount));
            }
            else{
                charge(_to, _amount);
            }
        }
        emit chargeResult(true, _amount);
    }
    
    //이달의 충전금액  ////인센티브 정확히 카운팅하는 함수  //결제히스토리용 함수
    function balanceWonOfMon(address _account) public view returns (uint128){
        if(incentiveCheck[_account].lastChargeDate < month){
            return 0;
        }
        else{
            return incentiveCheck[_account].wonOfMonth;
        }
    }
    
    //이번달 인센티브 확인
    function balanceIncOfMon(address _account) public view returns (uint128) {
        if(incentiveCheck[_account].lastChargeDate < month){
            return 0;
        }
        else{
            return incentiveCheck[_account].incentiveOfMonth;
        }
    }
    
    //현재 보유 원화
    function balance(address _account) external view virtual returns(uint256) {
        return balanceOf(_account);
        //  return balanceOf(_account) * (10 ** 18);
    }
    
    //원화 토큰 결제
    function payment(address _sender, address _recipient, uint128 _amount) public virtual returns (bool){
        _transfer(_sender, _recipient, _amount);
        // bz.paybackCharge(_sender,_amount);
        return true;
    }
    //매달 변경될때, aws람다를 사용해 백앤드에 요청을 보낸다. 요청받은 백앤드는 현재 시간(UNIX시간)을 setMonth에 입력 
    function setMonth(uint256 _month) public {
        month = _month;
    }

}