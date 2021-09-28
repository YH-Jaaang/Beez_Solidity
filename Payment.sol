//결제 : transfer로 원화, 비즈 교환 
//      구매페이백(원화로만 결제했을 경우 - 원화코인 1.0 %를 비즈로 전달)
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BeezToken.sol";
import "./WonToken.sol";

contract Payment {
    // BeezToken bz;
    event bzTokenPayback(bool result,address sender, address recipient, uint128 wonAmount, uint128 bzAmount);
    
    function beezBalance(BeezToken bzTokenAddr, address _to) public view returns (uint256){
        return bzTokenAddr.balance(_to);
        //return tokenAdderess.balance(to);
    }
    //사용가능 WON체크
    function wonBalance(WonToken wonTokenAddr, address _to) public view returns (uint256){
        return wonTokenAddr.balance(_to);
    }

    //결제 (가격이 같지않거나 페이가 부족한 경우는 웹에서 체크)
    function payment(WonToken wonTokenAddr, BeezToken bzTokenAddr, address _sender, address _recipient, uint128 _wonAmount, uint128 _bzAmount) public{

        require(wonTokenAddr.balance(_sender) >= _wonAmount);
        require(bzTokenAddr.balance(_sender) >= _bzAmount);
        wonTokenAddr.payment(_sender, _recipient, _wonAmount);
        bzTokenAddr.payment(_sender, _recipient, _bzAmount);
        bzTokenAddr.chargePayback(_sender, _wonAmount, msg.sender);
        
        //시스템이 이벤트를 watch하다가 catch해서 bzTokenAddr.charge(sender, _wonAmount);를 실행시킨다.

        emit bzTokenPayback(true, _sender, _recipient, _wonAmount, _bzAmount);
        
    }
    
  
    
}


    
