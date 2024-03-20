// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interface/IStaking721.sol";

abstract contract OptimizedStaking721 is IStaking721 {
    struct OptimizedStaker {
        uint40 conditionIdOflastUpdate;
        uint88 timeOfLastUpdate;
        uint128 unclaimedRewards;
        uint256[] tokensStaked;
    }

    /*///////////////////////////////////////////////////////////////
                            State variables / Mappings
    //////////////////////////////////////////////////////////////*/

    ///@dev Address of ERC721 NFT contract -- staked tokens belong to this contract.
    address public immutable stakingToken;

    ///@dev Next staking condition Id. Tracks number of conditon updates so far.
    uint40 private nextConditionId;

    ///@dev Mapping from staker address to Staker struct. See {struct IStaking721.Staker}.
    mapping(address => OptimizedStaker) public stakers;

    ///@dev Mapping from condition Id to staking condition. See {struct IStaking721.StakingCondition}
    mapping(uint256 => StakingCondition) private stakingConditions;

    constructor(address _stakingToken) {
        require(address(_stakingToken) != address(0), "collection address 0");
        stakingToken = _stakingToken;
    }

    /*///////////////////////////////////////////////////////////////
                        External/Public Functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice    Stake ERC721 Tokens.
     *
     *  @dev       See {_stake}. Override that to implement custom logic.
     *
     *  @param _tokenIds    List of tokens to stake.
     */
    function stake(uint256[] calldata _tokenIds) external {
        _stake(_tokenIds);
    }

    /**
     *  @notice    Withdraw staked tokens.
     *
     *  @dev       See {_withdraw}. Override that to implement custom logic.
     *
     *  @param _tokenIds    List of tokens to withdraw.
     */
    function withdraw(uint256[] calldata _tokenIds) external {
        _withdraw(_tokenIds);
    }

    /**
     *  @notice    Claim accumulated rewards.
     *
     *  @dev       See {_claimRewards}. Override that to implement custom logic.
     *             See {_calculateRewards} for reward-calculation logic.
     */
    function claimRewards() external {
        _claimRewards();
    }

    /**
     *  @notice  Set time unit. Set as a number of seconds.
     *           Could be specified as -- x * 1 hours, x * 1 days, etc.
     *
     *  @dev     Only admin/authorized-account can call it.
     *
     *
     *  @param _timeUnit    New time unit.
     */
    function setTimeUnit(uint256 _timeUnit) external virtual {
        if (!_canSetStakeConditions()) {
            revert("Not authorized");
        }

        StakingCondition memory condition = stakingConditions[nextConditionId - 1];
        require(_timeUnit != condition.timeUnit, "Time-unit unchanged.");

        _setStakingCondition(_timeUnit, condition.rewardsPerUnitTime);

        emit UpdatedTimeUnit(condition.timeUnit, _timeUnit);
    }

    /**
     *  @notice  Set rewards per unit of time.
     *           Interpreted as x rewards per second/per day/etc based on time-unit.
     *
     *  @dev     Only admin/authorized-account can call it.
     *
     *
     *  @param _rewardsPerUnitTime    New rewards per unit time.
     */
    function setRewardsPerUnitTime(uint256 _rewardsPerUnitTime) external virtual {
        if (!_canSetStakeConditions()) {
            revert("Not authorized");
        }

        StakingCondition memory condition = stakingConditions[nextConditionId - 1];
        require(_rewardsPerUnitTime != condition.rewardsPerUnitTime, "Reward unchanged.");

        _setStakingCondition(condition.timeUnit, _rewardsPerUnitTime);

        emit UpdatedRewardsPerUnitTime(condition.rewardsPerUnitTime, _rewardsPerUnitTime);
    }

    /**
     *  @notice View amount staked and total rewards for a user.
     *
     *  @param _staker          Address for which to calculated rewards.
     *  @return _tokensStaked   List of token-ids staked by staker.
     *  @return _rewards        Available reward amount.
     */
    function getStakeInfo(
        address _staker
    ) external view virtual returns (uint256[] memory _tokensStaked, uint256 _rewards) {
        _tokensStaked = stakers[_staker].tokensStaked;

        _rewards = _availableRewards(_staker);
    }

    function getTimeUnit() public view returns (uint256 _timeUnit) {
        _timeUnit = stakingConditions[nextConditionId - 1].timeUnit;
    }

    function getRewardsPerUnitTime() public view returns (uint256 _rewardsPerUnitTime) {
        _rewardsPerUnitTime = stakingConditions[nextConditionId - 1].rewardsPerUnitTime;
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Staking logic. Override to add custom logic.
    function _stake(uint256[] calldata _tokenIds) internal virtual {
        uint64 len = uint64(_tokenIds.length);
        require(len != 0, "Staking 0 tokens");

        address _stakingToken = stakingToken;

        if (stakers[_stakeMsgSender()].tokensStaked.length > 0) {
            _updateUnclaimedRewardsForStaker(_stakeMsgSender());
        } else {
            stakers[_stakeMsgSender()].timeOfLastUpdate = uint88(block.timestamp);
            stakers[_stakeMsgSender()].conditionIdOflastUpdate = nextConditionId - 1;
        }
        for (uint256 i = 0; i < len; ++i) {
            IERC721(_stakingToken).safeTransferFrom(_stakeMsgSender(), address(this), _tokenIds[i]);

            stakers[_stakeMsgSender()].tokensStaked.push(_tokenIds[i]);
        }

        emit TokensStaked(_stakeMsgSender(), _tokenIds);
    }

    /// @dev Withdraw logic. Override to add custom logic.
    function _withdraw(uint256[] calldata _tokenIds) internal virtual {
        uint256[] storage tokensStaked = stakers[_stakeMsgSender()].tokensStaked;
        uint256 _amountStaked = tokensStaked.length;
        uint64 len = uint64(_tokenIds.length);
        // We re-design the logic so that if the user wants to withdraw all tokens they can supply a zero-length array
        // to indicate this, and consequently we can optimize the implementation
        require(_amountStaked >= len || len == 0, "Withdrawing more than staked");

        address _stakingToken = stakingToken;

        _updateUnclaimedRewardsForStaker(_stakeMsgSender());

        if (len > 0) {
            for (uint256 i = 0; i < len; ++i) {
                uint256 tokensStakedLen = tokensStaked.length;
                for (uint256 stakedIndex = 0; stakedIndex < tokensStakedLen; ++stakedIndex) {
                    if (tokensStaked[stakedIndex] == _tokenIds[i]) {
                        tokensStaked[stakedIndex] = tokensStaked[tokensStakedLen - 1];
                        tokensStaked.pop();
                        break;
                    } else {
                        unchecked {
                            require(stakedIndex < tokensStakedLen - 1, "Token not staked by sender");
                        }
                    }
                }
                IERC721(_stakingToken).safeTransferFrom(address(this), _stakeMsgSender(), _tokenIds[i]);
            }
        } else {
            uint256[] memory _tokensStaked = tokensStaked;
            uint256 tokensStakedLen = _tokensStaked.length;
            delete stakers[_stakeMsgSender()].tokensStaked;
            for (uint256 stakedIndex = 0; stakedIndex < tokensStakedLen; ++stakedIndex) {
                IERC721(_stakingToken).safeTransferFrom(address(this), _stakeMsgSender(), _tokensStaked[stakedIndex]);
            }
        }

        emit TokensWithdrawn(_stakeMsgSender(), _tokenIds);
    }

    /// @dev Logic for claiming rewards. Override to add custom logic.
    function _claimRewards() internal virtual {
        uint256 rewards = stakers[_stakeMsgSender()].unclaimedRewards + _calculateRewards(_stakeMsgSender());

        require(rewards != 0, "No rewards");

        stakers[_stakeMsgSender()].timeOfLastUpdate = uint88(block.timestamp);
        stakers[_stakeMsgSender()].unclaimedRewards = 0;
        stakers[_stakeMsgSender()].conditionIdOflastUpdate = nextConditionId - 1;

        _mintRewards(_stakeMsgSender(), rewards);

        emit RewardsClaimed(_stakeMsgSender(), rewards);
    }

    /// @dev View available rewards for a user.
    function _availableRewards(address _user) internal view virtual returns (uint256 _rewards) {
        if (stakers[_user].tokensStaked.length == 0) {
            _rewards = stakers[_user].unclaimedRewards;
        } else {
            _rewards = stakers[_user].unclaimedRewards + _calculateRewards(_user);
        }
    }

    /// @dev Update unclaimed rewards for a users. Called for every state change for a user.
    function _updateUnclaimedRewardsForStaker(address _staker) internal virtual {
        uint128 rewards = _calculateRewards(_staker);
        stakers[_staker].unclaimedRewards += rewards;
        stakers[_staker].timeOfLastUpdate = uint88(block.timestamp);
        stakers[_staker].conditionIdOflastUpdate = nextConditionId - 1;
    }

    /// @dev Set staking conditions.
    function _setStakingCondition(uint256 _timeUnit, uint256 _rewardsPerUnitTime) internal virtual {
        require(_timeUnit != 0, "time-unit can't be 0");
        uint256 conditionId = nextConditionId;
        nextConditionId += 1;

        stakingConditions[conditionId] = StakingCondition({
            timeUnit: _timeUnit,
            rewardsPerUnitTime: _rewardsPerUnitTime,
            startTimestamp: block.timestamp,
            endTimestamp: 0
        });

        if (conditionId > 0) {
            stakingConditions[conditionId - 1].endTimestamp = block.timestamp;
        }
    }

    /// @dev Calculate rewards for a staker.
    function _calculateRewards(address _staker) internal view virtual returns (uint128 _rewards) {
        OptimizedStaker storage staker = stakers[_staker];
        uint256 amountStaked = staker.tokensStaked.length;

        uint256 _stakerConditionId = staker.conditionIdOflastUpdate;
        uint256 _nextConditionId = nextConditionId;
        uint256 _timeOfLastUpdate = staker.timeOfLastUpdate;
        uint256 _rewards256;

        for (uint256 i = _stakerConditionId; i < _nextConditionId; i += 1) {
            StakingCondition memory condition = stakingConditions[i];

            uint256 startTime = i != _stakerConditionId ? condition.startTimestamp : _timeOfLastUpdate;
            uint256 endTime = condition.endTimestamp != 0 ? condition.endTimestamp : block.timestamp;

            (bool noOverflowProduct, uint256 rewardsProduct) = Math.tryMul(
                (endTime - startTime) * amountStaked,
                condition.rewardsPerUnitTime
            );
            (bool noOverflowSum, uint256 rewardsSum) = Math.tryAdd(_rewards256, rewardsProduct / condition.timeUnit);

            _rewards256 = noOverflowProduct && noOverflowSum ? rewardsSum : _rewards256;
        }

        if (_rewards256 > type(uint128).max) {
            _rewards = type(uint128).max;
        } else {
            _rewards = uint128(_rewards256);
        }
    }

    /*////////////////////////////////////////////////////////////////////
        Optional hooks that can be implemented in the derived contract
    ///////////////////////////////////////////////////////////////////*/

    /// @dev Exposes the ability to override the msg sender -- support ERC2771.
    function _stakeMsgSender() internal virtual returns (address) {
        return msg.sender;
    }

    /*///////////////////////////////////////////////////////////////
        Virtual functions to be implemented in derived contract
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice View total rewards available in the staking contract.
     *
     */
    function getRewardTokenBalance() external view virtual returns (uint256 _rewardsAvailableInContract);

    /**
     *  @dev    Mint/Transfer ERC20 rewards to the staker. Must override.
     *
     *  @param _staker    Address for which to calculated rewards.
     *  @param _rewards   Amount of tokens to be given out as reward.
     *
     *  For example, override as below to mint ERC20 rewards:
     *
     * ```
     *  function _mintRewards(address _staker, uint256 _rewards) internal override {
     *
     *      TokenERC20(rewardTokenAddress).mintTo(_staker, _rewards);
     *
     *  }
     * ```
     */
    function _mintRewards(address _staker, uint256 _rewards) internal virtual;

    /**
     *  @dev    Returns whether staking restrictions can be set in given execution context.
     *          Must override.
     *
     *
     *  For example, override as below to restrict access to admin:
     *
     * ```
     *  function _canSetStakeConditions() internal override {
     *
     *      return msg.sender == adminAddress;
     *
     *  }
     * ```
     */
    function _canSetStakeConditions() internal view virtual returns (bool);
}