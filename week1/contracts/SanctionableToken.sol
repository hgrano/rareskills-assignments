// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title Sanctionable Token
/// @author Huw Grano
/// @notice A fungible token which allows the contract owner to sanction address, preventing these addresses from
/// sending or receiving tokens
contract SanctionableToken is ERC20, Ownable2Step {
    mapping(address => bool) private sanctioned;

    /// @param name Descriptive name for this token
    /// @param symbol ERC20 symbol for this token
    /// @param initialOwner The address to receive the initial supply of tokens and who will be the contract owner
    /// @param initialSupply The initial quantity of tokens
    constructor(
        string memory name,
        string memory symbol,
        address initialOwner,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable(initialOwner) {
        _mint(initialOwner, initialSupply);
    }

    /// @notice Sanction an address making it unable to send or receive tokens
    /// @dev reverts if not called by the contract owner
    /// @param toSanction The address to be sanctioned
    function sanction(address toSanction) public onlyOwner {
        sanctioned[toSanction] = true;
    }

    /// @notice Lift sanctions on address
    /// @dev reverts if not called by the contract owner
    /// @param toUnSanction The address to remove sanctions from
    function unSanction(address toUnSanction) public onlyOwner {
        delete sanctioned[toUnSanction];
    }

    function _update(address from, address to, uint256 value) internal override {
        require(!sanctioned[from], "SanctionableToken: cannot transfer from sanctioned address");
        require(!sanctioned[to], "SanctionableToken: cannot transfer to sanctioned address");
        ERC20._update(from, to, value);
    }
}
