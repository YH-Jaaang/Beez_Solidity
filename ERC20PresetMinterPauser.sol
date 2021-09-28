// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";


contract ERC20PresetMinterPauser is AccessControlEnumerable, ERC20Burnable{
     
    // uint basemonth = 1633014000;
    // uint[60]ChargeIdx;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    // require(basemonth+30days)
    

    //이번달 충전 금액
    mapping(address=>uint) WonOfMonth;

    constructor() ERC20('WON', 'WON') {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }
    
    function _IncentiveCharge(address _to, uint256 _amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(_to, _amount+(_amount/10));
   
    }
    
    function _Charge(address _to, uint256 _amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(_to, _amount);
    }

   
}