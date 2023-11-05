// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
using SafeERC20 for IERC20;

contract UntrustedEscrow {
    struct Escrow {
        address token;
        address buyer;
        address seller;
        uint256 value;
        uint256 unlockTime;
    }
    mapping(uint256 => Escrow) escrows;

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
        uint256 withdrawnTime
    );

    function escrow(uint256 id, address token, address seller, uint256 value, uint256 valueWithFee) external {
        require(value > 0, "Cannot escrow zero tokens");
        require(escrows[id].value == 0, "Cannot escrow using the same id twice");
        uint256 _unlockTime;
        unchecked {
            _unlockTime = block.timestamp + 3 days;
        }
        escrows[id] = Escrow(
            {
                token: token,
                buyer: msg.sender,
                seller: seller,
                value: value,
                unlockTime: _unlockTime
            }
        );
        uint256 currentBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), valueWithFee);
        uint256 newBalance = IERC20(token).balanceOf(address(this));
        require(newBalance - currentBalance == value, "Must have expected available balance after transfering");

        emit Escrowed(id, token, msg.sender, seller, value, _unlockTime);
    }

    function withdraw(uint256 id) external {
        Escrow memory escr = escrows[id];
        require(block.timestamp > escr.unlockTime, "Can only withdraw after the unlock time");
        delete escrows[id];
        IERC20(escr.token).safeTransfer(escr.seller, escr.value);

        emit Withdrawn(id, block.timestamp);
    }
}
