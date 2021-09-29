// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./Payment.sol";

contract BeezToken is AccessControlEnumerable, ERC20Burnable{
  
    mapping (address=>uint128) beezOfMonth;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    //Payment payment;
    constructor() ERC20('BEEZ', 'BEEZ') {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        //payment = Payment(msg.sender);
    }
    
    
    //결제, 리뷰 페이백  external- 컨트랙트 바깥에서만 호출될 수 있고 컨트랙트 내의 다른 함수에서 호출 X(public과 동일)
    function Payback(address to, uint128 amount) external virtual  {
        _mint(to, amount/100);
        beezOfMonth[to] = beezOfMonth[to] + amount/100;
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
        return beezOfMonth[_account];
        
    }
   
}