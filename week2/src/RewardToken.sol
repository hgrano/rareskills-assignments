// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title RewardToken
/// @author Huw Grano
/// @notice ERC20 token which can be minted by a designated address
contract RewardToken is ERC20, Ownable2Step {
    address private minter;

    /// @param name_ Descriptive name for this token
    /// @param symbol_ ERC20 symbol for this token
    /// @param owner_ The administrator of the contract who can set the address which is allowed to mint
    constructor(string memory name_, string memory symbol_, address owner_) ERC20(name_, symbol_) Ownable(owner_) {}

    /// @notice Set the address allowed to mint
    /// @param newMinter The address which will be allowed to mint
    function setMinter(address newMinter) external onlyOwner {
        minter = newMinter;
    }

    /// @notice Mint new tokens to the address
    /// @param to The address to mint to
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) external {
        require(msg.sender == minter, "RewardToken: ownly the minter can mint");
        _mint(to, amount);
    }
}
