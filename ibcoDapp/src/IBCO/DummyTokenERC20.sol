// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// Access control
contract Ownerable {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() internal returns (address owner_) {
        owner_ = _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is only owner.");
        _;
    }
}

contract DummyTokenERC20 is ERC20("Dummy ERC20 Token", "DET"), Ownerable {
    uint256 constant initialSupply = 200_000_000 * (10 ** 18);

    constructor() {
        _mint(address(this), initialSupply);
    }

    function mintTo(address account_, uint256 amount_) public onlyOwner {
        _mint(account_, amount_);
    }
}
