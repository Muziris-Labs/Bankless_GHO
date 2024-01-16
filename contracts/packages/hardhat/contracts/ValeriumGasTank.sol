//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract ValeriumGasTank {
    address public Owner;

    constructor() {
        Owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == Owner, "Only owner can call this function");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        Owner = newOwner;
    }

    function withdraw(address payable to, uint256 amount) public onlyOwner {
        to.transfer(amount);
    }

    function withdrawAll(address payable to) public onlyOwner {
        to.transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}