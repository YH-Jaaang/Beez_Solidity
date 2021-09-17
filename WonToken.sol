// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./BeezToken.sol";

contract WonToken is AccessControlEnumerable, ERC20Burnable{
    
    //인센티브 비율
    uint128 incentiveRate;
    uint128 maxIncentive = 500000;
    uint128 maxWonCharge = 2000000;
    uint128 minWonCharge = 10000;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    //이번달 충전 금액
    mapping(address=>uint128) wonOfMonth;
    //이번달 인센티브 금액
    mapping(address=>uint128) incentiveOfMonth;
    //충전결과 로그
    event chargeResult(bool result, uint128 chargeAmount);
    
    constructor() ERC20('WON', 'WON') {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }
    
    //인센티브 충전
    function incentiveCharge(address _to, uint128 _amount) internal virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        incentiveRate = _amount/10;
        _mint(_to, _amount + incentiveRate);
        incentiveOfMonth[_to] += incentiveRate;
    }
    
    //충전
    function charge(address _to, uint256 _amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(_to, _amount);
    }
    
    function chargeCheck(address _to, uint128  _amount) public {
         //한달 최대 충전량
        require(_amount >= minWonCharge);
        require(wonOfMonth[_to] + _amount <= maxWonCharge);
        //여기서 우리가 생각해야 되는게 30만원 충전시 인센티브 받고 21만원 충전 했을 경우 20만원은 인센티브 받고 1만원은 그냥 충전 **인센티브 붙는걸 생각 해야됨
        wonOfMonth[_to] += _amount;
        if(wonOfMonth[_to] <= maxIncentive){
            incentiveCharge(_to, _amount);
        }else{
            if(wonOfMonth[_to] - _amount <maxIncentive){
                charge(_to, wonOfMonth[_to] - maxIncentive);
                incentiveCharge(_to, maxIncentive - (wonOfMonth[_to] - _amount));
            }
            else{
                charge(_to, _amount);
            }
        }
        emit chargeResult(true, _amount);
    }
    
    //이번달 충전금액 확인
    function balanceWonOfMon(address _account) public view returns (uint128) {
        return wonOfMonth[_account];
    }
    //이번달 인센티브 확인
    function balanceIncOfMon(address _account) public view returns (uint128) {
        return incentiveOfMonth[_account];
    }
    //이번달 충전금액, 인센트브 초기화
    function initOfMonth() public {
        wonOfMonth[msg.sender] = 0;
        //incentiveOfMonth = 0;
    }
    function balance(address _account) external view virtual returns(uint256) {
        return balanceOf(_account);
    }
    //결제
    function payment(address _sender, address _recipient, uint256 _amount) public virtual returns (bool){
        _transfer(_sender, _recipient, _amount);
        return true;
    }
    // function withdraw(address _to, uint256 _amount) public virtual returns (bool){
    //      _burn(_to, _amount);
    //     return true;
    // }

}