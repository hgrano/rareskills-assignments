// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IStaking721Mock} from "../interface/IStaking721Mock.sol";
import {ERC20Impl} from "./ERC20.sol";
import {Staking721} from "../../src/Staking721.sol";

contract DefaultStaking721Impl is IStaking721Mock, Staking721, IERC721Receiver {
    address public rewardTokenAddress;

    constructor(address _stakingToken, address _rewardTokenAddress) Staking721(_stakingToken) {
        rewardTokenAddress = _rewardTokenAddress;
    }

    function _canSetStakeConditions() internal view override returns (bool) {
        return true;
    }

    function _mintRewards(address _staker, uint256 _rewards) internal override {
        ERC20Impl(rewardTokenAddress).mint(_staker, _rewards);
    }

    // Method is not needed for testing gas optimization
    function getRewardTokenBalance() external view override returns (uint256) {
        revert("Unsupported function");
    }

    function setStakingCondition(uint256 _timeUnit, uint256 _rewardsPerUnitTime) external {
        _setStakingCondition(_timeUnit, _rewardsPerUnitTime);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
