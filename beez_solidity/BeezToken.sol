// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
// import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./Payment.sol";

contract BeezToken is AccessControlEnumerable, ERC20{
    
    constructor() ERC20('BEEZ', 'BEEZ') {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        //payment = Payment(msg.sender);
    }
    
    struct payback{
        uint256 lastPaybackDate;      //마지막 Payback날짜 체크
        uint128 beezOfMonth;         //이번달 충전 금액  //maxWonCharge - wonOfMonth[address] : 이번달 충전가능금액(charge.vue에 출력)
    }
    
    uint256 month = 1630422000;   //매달 초기화(이달 1일을 나타냄)
    mapping (address => payback) paybackCheck;  //주소 넣어서 인센티브 구조체 가져오는 매핑                    //인센티브 비율
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
/******************************************************************************************************************/
/********사용자, 소상공인 MAIN화면 매달 초기화 함수(사용자 : 이달의 beez & 소상공인 : 토큰매출,이번달beez)********/

    //매달 초기화 함수
    function updateMonth(address _address, uint256 _date) private {
        //금액 충전시 마지막으로 인센티브 충전된 날짜가 지난달인 경우 (block.timestamp >= month && =>이건 빼야됨)
        if(paybackCheck[_address].lastPaybackDate < month){
            paybackCheck[_address].beezOfMonth = 0;  //인센티브 밸런스 초기화(여기서 이번에 충전된 )
        }
        //(나중에 다시 block.timestamp으로 수정)
        paybackCheck[_address].lastPaybackDate = _date; //최근 인센티브 충전된 날짜 현재시간으로 업데이트
    }
        
    //매달 변경될때, aws람다를 사용해 백앤드에 요청을 보낸다. 요청받은 백앤드는 현재 시간(UNIX시간)을 setMonth에 입력 
    function setMonth(uint256 _month) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        month = _month;
    }
    
/******************************************************************************************************************/
/*********사용자, 소상공인 결재 / 사용자 리뷰페이백 / 소상공인 환전 함수***********/

    //결제
    function payment(address _sender, address _recipient, uint128 _amount, uint256 _date) public virtual returns (bool){
         updateMonth(_recipient, _date); //_date는 나중에 뺄꺼임. 이번달 첫 결재할 경우, 소상공인 incentiveCheck[_recipient].wonOfMonth 0으로 만들기 위해 //
        _transfer(_sender, _recipient, _amount); //won 결제
        paybackCheck[_recipient].beezOfMonth += _amount;   //소상공인 (이번달)현금매출 증가
        return true;
    }
    
    //리뷰 페이백  external- 컨트랙트 바깥에서만 호출될 수 있고 컨트랙트 내의 다른 함수에서 호출 X(public과 동일)
    function Payback(address _to, uint128 _amount, uint256 _date) external virtual  {
        updateMonth(_to, _date);
        _mint(_to, _amount/100);
        paybackCheck[_to].beezOfMonth = paybackCheck[_to].beezOfMonth + _amount/100;
    }
    
    //소상공인 환전 함수 
     function exchange(address _to, uint256  _amount) public {
         require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _burn(_to, _amount);
     }
     
/******************************************************************************************************************/
/*************************사용자, 소상공인 MAIN화면에 출력되는 비즈토큰 view 함수*********************************/
    
    //보유 bz 확인
    function balance(address _account) external view virtual returns(uint256) {
        return balanceOf(_account);
    }
    
    //이달의 bz체크, 월 마다 리셋되야함
    function balanceBeezOfMon (address _account) external view returns (uint128) {
        if(paybackCheck[_account].lastPaybackDate < month){
            return 0;
        }
        else{
            return paybackCheck[_account].beezOfMonth;
        }
    }

/******************************************************************************************************************/   
}