// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title God Mode Token Token
/// @author Huw Grano
/// @notice A fungible token that allows the owner to transfer tokens between any two addresses
contract GodModeToken is ERC20, Ownable2Step {
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

    /// @notice Transfer tokens from one address to another
    /// @dev emits a Transfer event
    /// @dev reverts if the msg.sender is not the contract owner or is not sufficiently approved to make the transfer
    /// @param from Address to transfer from
    /// @param to Address to transfer to
    /// @param value The amount of tokens send
    function transferFrom(address from, address to, uint256 value) override public returns (bool) {
        if (msg.sender == owner()) {
            _transfer(from, to, value);
            return true;
        } else {
            return ERC20.transferFrom(from, to, value);
        }
    }
}
