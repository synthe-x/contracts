// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract SyntexMock {
    constructor()  {}

    function isL1Admin(address _address) external returns(bool) {
        return true;
    }
    
    function isL2Admin(address _address) external returns(bool) {
        return true;
    }
}