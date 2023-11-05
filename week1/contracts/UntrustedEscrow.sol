// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UntrustedEscrow {
    using SafeERC20 for IERC20;

    struct Escrow {
        address token;
        address buyer;
        address seller;
        uint256 value;
        uint256 unlockTime;
    }

    mapping(uint256 => Escrow) private escrows;

    event Escrowed(
        uint256 indexed id,
        address token,
        address indexed buyer,
        address indexed seller,
        uint256 value,
        uint256 unlockTime
    );
    event Withdrawn(
        uint256 indexed id,
        address token,
        address indexed buyer,
        address indexed seller,
        uint256 value,
        uint256 unlockTime
    );

    /// @notice Lock ERC20 tokens in escrow for a period of 3 days
    /// @dev emits an Escrowed event
    /// @dev reverts if this contract is not sufficiently approved by the ERC20
    /// @dev reverts if the ERC20 transfer does not behave as expected, such as resulting in an insufficient increase
    /// in balance.
    /// @param id A unique identifier for this escrow
    /// @param token The address of the ERC20 token to be deposited
    /// @param seller The address which will be allowed to receive the tokens in 3 days time
    /// @param value The amount of ERC20 tokens send, which may be less than the amount that will be held in escrow if
    /// the token charges transaction fees
    function escrow(uint256 id, address token, address seller, uint256 value) external {
        require(value > 0, "UntrustedEscrow: cannot escrow zero tokens");
        require(escrows[id].value == 0, "UntrustedEscrow: cannot escrow using the same id twice");
        uint256 _unlockTime;
        unchecked {
            _unlockTime = block.timestamp + 3 days;
        }
        uint256 initialBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), value);
        uint256 finalBalance = IERC20(token).balanceOf(address(this));
        escrows[id] = Escrow(
            {
                token: token,
                buyer: msg.sender,
                seller: seller,
                value: finalBalance - initialBalance,
                unlockTime: _unlockTime
            }
        );

        emit Escrowed(id, token, msg.sender, seller, value, _unlockTime);
    }

    /// @notice Withdraw ERC20 tokens from escrow
    /// @dev emits a Withdrawn event
    /// @dev reverts if no escrow exists for the given id
    /// @dev reverts if the block.timestamp is not more than 3 days after the tokens were locked
    /// @param id A unique identifier for this escrow
    function withdraw(uint256 id) external {
        Escrow memory escr = escrows[id];
        require(block.timestamp > escr.unlockTime, "UntrustedEscrow: can only withdraw after the unlock time");
        delete escrows[id];
        IERC20(escr.token).safeTransfer(escr.seller, escr.value);

        emit Withdrawn(id, escr.token, escr.buyer, escr.seller, escr.value, escr.unlockTime);
    }
}
