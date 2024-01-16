//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract ValeriumStorage {
    
    struct ValeriumDetails {
        address walletAddress;
        bool isUsed;
    }

    mapping(string => ValeriumDetails) public ValeriumNameToDetails;

    function addValerium(string memory name, address walletAddress) internal {
        ValeriumNameToDetails[name] = ValeriumDetails(walletAddress, true);
    }

    function _checkValerium(string memory name) internal view {
        require(ValeriumNameToDetails[name].isUsed, "Valerium: Invalid Valerium");
    }
    
    function getValerium(string memory name) external view returns (ValeriumDetails memory) {
        ValeriumDetails memory details = ValeriumNameToDetails[name];
        return details;
    }

    modifier isValidValerium(string memory name) {
        _checkValerium(name);
        _;
    }

}