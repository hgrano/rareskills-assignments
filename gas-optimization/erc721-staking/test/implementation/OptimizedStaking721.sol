// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IStaking721Mock} from "../interface/IStaking721Mock.sol";
import {ERC20Impl} from "./ERC20.sol";
import {OptimizedStaking721} from "../../src/OptimizedStaking721.sol";

contract OptimizedStaking721Impl is IStaking721Mock, OptimizedStaking721, IERC721Receiver {
    address private immutable rewardToken;

    constructor(address _stakingToken, address _rewardToken) OptimizedStaking721(_stakingToken) {
        rewardToken = _rewardToken;
    }

    function _canSetStakeConditions() internal view override returns (bool) {
        return true;
    }

    function _mintRewards(address _staker, uint256 _rewards) internal override {
        ERC20Impl(rewardToken).mint(_staker, _rewards);
    }

    // Method is not needed for testing gas optimization
    function getRewardTokenBalance() external view override returns (uint256) {
        revert("Unsupported function");
    }

    function setStakingCondition(uint32 _timeUnit, uint128 _rewardsPerUnitTime) external {
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
