// SPDX-License-Identifier: MIT

pragma solidity >=0.6.00;

// Based on openzeppelin-solidity@2.5.0:  openzeppelin-solidity\contracts\access\roles\CapperRole.sol

import "../Roles.sol";

contract TextileRole {
    using Roles for Roles.Role;

    event TextileAdded(address indexed account);
    event TextileRemoved(address indexed account);

    Roles.Role private _Textiles;

    constructor () {
        _addTextile(msg.sender);
    }

    modifier onlyTextile() {
        require(isTextile(msg.sender), "TextileRole: caller does not have the Textile role");
        _;
    }

    function isTextile(address account) public view returns (bool) {
        return _Textiles.has(account);
    }

    function addTextile(address account) public onlyTextile {
        _addTextile(account);
    }

    function renounceTextile() public {
        _removeTextile(msg.sender);
    }

    function _addTextile(address account) internal {
        _Textiles.add(account);
        emit TextileAdded(account);
    }

    function _removeTextile(address account) internal {
        _Textiles.remove(account);
        emit TextileRemoved(account);
    }
}