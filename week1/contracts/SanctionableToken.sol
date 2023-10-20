// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

// TODO fix version
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// using SafeERC20 for IERC20;
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

// import "openzeppelin-contracts-5.0.0/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts@5.0.0/access/Ownable.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract SanctionableToken is ERC20, Ownable2Step {
    mapping(address => bool) private sanctioned;

    // TODO add events?

    constructor(
        string memory name,
        string memory symbol,
        address initialOwner,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable(initialOwner) {
        _mint(initialOwner, initialSupply);
    }

    function sanction(address toSanction) public onlyOwner {
        sanctioned[toSanction] = true;
    }

    function unSanction(address toUnSanction) public onlyOwner {
        delete sanctioned[toUnSanction];
    }

    function _update(address from, address to, uint256 value) internal override {
        require(!sanctioned[from], "SanctionableToken: cannot transfer from sanctioned address");
        require(!sanctioned[to], "SanctionableToken: cannot transfer to sanctioned address");
        ERC20._update(from, to, value);
    }
}
