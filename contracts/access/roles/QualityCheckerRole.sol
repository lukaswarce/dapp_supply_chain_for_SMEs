// SPDX-License-Identifier: MIT

pragma solidity >=0.6.00;

// Based on openzeppelin-solidity@2.5.0:  openzeppelin-solidity\contracts\access\roles\CapperRole.sol

import "../Roles.sol";

contract QualityCheckerRole {
    using Roles for Roles.Role;

    event QualityCheckerAdded(address indexed account);
    event QualityCheckerRemoved(address indexed account);

    Roles.Role private _QualityCheckers;

    constructor () {
        _addQualityChecker(msg.sender);
    }

    modifier onlyQualityChecker() {
        require(isQualityChecker(msg.sender), "QualityCheckerRole: caller does not have the QualityChecker role");
        _;
    }

    function isQualityChecker(address account) public view returns (bool) {
        return _QualityCheckers.has(account);
    }

    function addQualityChecker(address account) public onlyQualityChecker {
        _addQualityChecker(account);
    }

    function renounceQualityChecker() public {
        _removeQualityChecker(msg.sender);
    }

    function _addQualityChecker(address account) internal {
        _QualityCheckers.add(account);
        emit QualityCheckerAdded(account);
    }

    function _removeQualityChecker(address account) internal {
        _QualityCheckers.remove(account);
        emit QualityCheckerRemoved(account);
    }
}