// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ILooksRareToken} from "./interfaces/ILooksRareToken.sol";
import {ITokenDistributor} from "./interfaces/ITokenDistributor.sol";

/**
 * @title OptimizedTokenDistributor
 * @notice It handles the distribution of LOOKS token.
 * It auto-adjusts block rewards over a set number of periods.
 */
contract OptimizedTokenDistributor is ReentrancyGuard, ITokenDistributor {
    using SafeERC20 for IERC20;
    using SafeERC20 for ILooksRareToken;

    struct StakingPeriod {
        // Single slot
        uint32 periodLengthInBlock; // Given 12 seconds per block, this can go up to a maximum of ~1600 years
        uint112 rewardPerBlockForOthers;
        uint112 rewardPerBlockForStaking;
    }

    struct UserInfo {
        uint128 amount; // Amount of staked tokens provided by user
        uint128 rewardDebt; // Reward debt
    }

    // Precision factor for calculating rewards
    uint256 public constant PRECISION_FACTOR = 10**12;

    ILooksRareToken public immutable looksRareToken;

    address public immutable tokenSplitter;

    // Number of reward periods
    uint16 public immutable NUMBER_PERIODS; // Max of ~65,000 periods

    // Block number when rewards start
    uint40 public immutable START_BLOCK;

    // BEGIN SLOT
    // Accumulated tokens per share
    // Assuming the token has 18 decimal places, coupled with the 12 decimal places for the PRECISION_FACTOR we can
    // store a max value of ~1.46 * 10**18 tokens in this variable
    uint160 public accTokenPerShare; 

    // Current phase for rewards
    uint16 public currentPhase; // Max of ~65,000

    // Block number when rewards end
    uint40 public endBlock;

    // Block number of the last update
    uint40 public lastRewardBlock;
    // END SLOT

    // BEGIN SLOT
    // Tokens distributed per block for other purposes (team + treasury + trading rewards)
    // Assuming the token has 18 decimal places, then this variable can store at most ~5.2 * 10**18 tokens
    uint112 public rewardPerBlockForOthers;

    // Tokens distributed per block for staking
    // Assuming the token has 18 decimal places, then this variable can store at most ~5.2 * 10**18 tokens
    uint112 public rewardPerBlockForStaking;
    // END SLOT

    // BEGIN SLOT
    // Total amount staked
    uint256 public totalAmountStaked;
    // END SLOT

    mapping(uint256 => StakingPeriod) public stakingPeriod;

    mapping(address => UserInfo) public userInfo;

    event Compound(address indexed user, uint256 harvestedAmount);
    event Deposit(address indexed user, uint256 amount, uint256 harvestedAmount);
    event NewRewardsPerBlock(
        uint256 indexed currentPhase,
        uint256 startBlock,
        uint256 rewardPerBlockForStaking,
        uint256 rewardPerBlockForOthers
    );
    event Withdraw(address indexed user, uint256 amount, uint256 harvestedAmount);

    /**
     * @notice Constructor
     * @param _looksRareToken LOOKS token address
     * @param _tokenSplitter token splitter contract address (for team and trading rewards)
     * @param _startBlock start block for reward program
     * @param _rewardsPerBlockForStaking array of rewards per block for staking
     * @param _rewardsPerBlockForOthers array of rewards per block for other purposes (team + treasury + trading rewards)
     * @param _periodLengthesInBlocks array of period lengthes
     * @param _numberPeriods number of periods with different rewards/lengthes (e.g., if 3 changes --> 4 periods)
     */
    constructor(
        address _looksRareToken,
        address _tokenSplitter,
        uint40 _startBlock,
        uint112[] memory _rewardsPerBlockForStaking,
        uint112[] memory _rewardsPerBlockForOthers,
        uint32[] memory _periodLengthesInBlocks,
        uint16 _numberPeriods
    ) {
        require(
            (_periodLengthesInBlocks.length == _numberPeriods) &&
                (_rewardsPerBlockForStaking.length == _numberPeriods) &&
                (_rewardsPerBlockForStaking.length == _numberPeriods),
            "Distributor: Lengthes must match numberPeriods"
        );

        // 1. Operational checks for supply
        uint256 nonCirculatingSupply = ILooksRareToken(_looksRareToken).SUPPLY_CAP() -
            ILooksRareToken(_looksRareToken).totalSupply();

        uint256 amountTokensToBeMinted;

        for (uint256 i = 0; i < _numberPeriods; i++) {
            amountTokensToBeMinted +=
                (_rewardsPerBlockForStaking[i] * _periodLengthesInBlocks[i]) +
                (_rewardsPerBlockForOthers[i] * _periodLengthesInBlocks[i]);

            stakingPeriod[i] = StakingPeriod({
                rewardPerBlockForStaking: _rewardsPerBlockForStaking[i],
                rewardPerBlockForOthers: _rewardsPerBlockForOthers[i],
                periodLengthInBlock: _periodLengthesInBlocks[i]
            });
        }

        require(amountTokensToBeMinted == nonCirculatingSupply, "Distributor: Wrong reward parameters");

        // 2. Store values
        looksRareToken = ILooksRareToken(_looksRareToken);
        tokenSplitter = _tokenSplitter;
        rewardPerBlockForStaking = _rewardsPerBlockForStaking[0];
        rewardPerBlockForOthers = _rewardsPerBlockForOthers[0];

        START_BLOCK = _startBlock;
        endBlock = _startBlock + _periodLengthesInBlocks[0];

        NUMBER_PERIODS = _numberPeriods;

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = _startBlock;
    }

    /**
     * @notice Deposit staked tokens and compounds pending rewards
     * @param amount amount to deposit (in LOOKS)
     */
    function deposit(uint256 amount) external nonReentrant {
        // To make the tests compile `uint256` is used as the parameter type so it is the same signature as the
        // original contract, but in practice it should be changed to uint128
        require(amount > 0, "Deposit: Amount must be > 0");

        // Update pool information
        _updatePool();

        // Transfer LOOKS tokens to this contract
        looksRareToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 pendingRewards;
        uint256 userAmount = userInfo[msg.sender].amount;
        uint256 accTokenPerShare_ = accTokenPerShare;

        // If not new deposit, calculate pending rewards (for auto-compounding)
        if (userAmount > 0) {
            pendingRewards =
                ((userAmount * accTokenPerShare_) / PRECISION_FACTOR) - userInfo[msg.sender].rewardDebt;
        }

        uint256 newAmount = userAmount + amount + pendingRewards;
        require(newAmount <= type(uint128).max, "Deposit: New amount must be within range of uint128");

        // Adjust user information
        userInfo[msg.sender].amount = uint128(newAmount);

        uint256 newRewardDebt = (newAmount * accTokenPerShare_) / PRECISION_FACTOR;
        require(newRewardDebt <= type(uint128).max, "Deposit: New reward debt must be within range of uint128");
        userInfo[msg.sender].rewardDebt = uint128(newRewardDebt);

        // Increase totalAmountStaked
        totalAmountStaked += (amount + pendingRewards);

        emit Deposit(msg.sender, amount, pendingRewards);
    }

    /**
     * @notice Compound based on pending rewards
     */
    function harvestAndCompound() external nonReentrant {
        // Update pool information
        _updatePool();

        uint256 userAmount = uint256(userInfo[msg.sender].amount);
        uint256 accTokenPerShare_ = uint256(accTokenPerShare);

        // Calculate pending rewards
        uint256 pendingRewards = ((userAmount * accTokenPerShare_) / PRECISION_FACTOR) -
            uint256(userInfo[msg.sender].rewardDebt);

        // Return if no pending rewards
        if (pendingRewards == 0) {
            // It doesn't throw revertion (to help with the fee-sharing auto-compounding contract)
            return;
        }

        uint256 newAmount = userAmount + pendingRewards;
        require(newAmount <= type(uint128).max, "harvestAndCompound: New amount must be within range of uint128");

        // Adjust user amount for pending rewards
        userInfo[msg.sender].amount = uint128(newAmount);

        // Adjust totalAmountStaked
        totalAmountStaked += pendingRewards;

        // Recalculate reward debt based on new user amount
        uint256 newRewardDebt = (newAmount * accTokenPerShare_) / PRECISION_FACTOR;
        require(
            newRewardDebt <= type(uint128).max,
            "harvestAndCompound: New reward debt must be within range of uint128"
        );
        userInfo[msg.sender].rewardDebt = uint128(newRewardDebt);

        emit Compound(msg.sender, pendingRewards);
    }

    /**
     * @notice Update pool rewards
     */
    function updatePool() external nonReentrant {
        _updatePool();
    }

    /**
     * @notice Withdraw staked tokens and compound pending rewards
     * @param amount amount to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant {
        uint256 userAmount = userInfo[msg.sender].amount;
        require(
            (userAmount >= amount) && (amount > 0),
            "Withdraw: Amount must be > 0 or lower than user balance"
        );

        // Update pool
        _updatePool();

        uint256 accTokenPerShare_ = accTokenPerShare;

        // Calculate pending rewards
        uint256 pendingRewards = ((userAmount * accTokenPerShare_) / PRECISION_FACTOR) -
            userInfo[msg.sender].rewardDebt;

        // Adjust user information
        uint256 newAmount = userAmount + pendingRewards - amount;
        require(newAmount <= type(uint128).max, "withdraw: new amount must be within range of uint128");
        userInfo[msg.sender].amount = uint128(newAmount);
        uint256 newRewardDebt = (newAmount * accTokenPerShare_) / PRECISION_FACTOR;
        require(newRewardDebt <= type(uint128).max, "withdraw: new reward debt must be within range of uint128");
        userInfo[msg.sender].rewardDebt = uint128(newRewardDebt);

        // Adjust total amount staked
        totalAmountStaked = totalAmountStaked + pendingRewards - amount;

        // Transfer LOOKS tokens to the sender
        looksRareToken.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount, pendingRewards);
    }

    /**
     * @notice Withdraw all staked tokens and collect tokens
     */
    function withdrawAll() external nonReentrant {
        uint256 userAmount = userInfo[msg.sender].amount;
        require(userAmount > 0, "Withdraw: Amount must be > 0");

        // Update pool
        _updatePool();

        // Calculate pending rewards and amount to transfer (to the sender)
        uint256 pendingRewards = ((userAmount * accTokenPerShare) / PRECISION_FACTOR) -
            userInfo[msg.sender].rewardDebt;

        uint256 amountToTransfer = userAmount + pendingRewards;

        // Adjust total amount staked
        totalAmountStaked = totalAmountStaked - userAmount;

        // Adjust user information
        delete userInfo[msg.sender];

        // Transfer LOOKS tokens to the sender
        looksRareToken.safeTransfer(msg.sender, amountToTransfer);

        emit Withdraw(msg.sender, amountToTransfer, pendingRewards);
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param user address of the user
     * @return Pending rewards
     */
    function calculatePendingRewards(address user) external view returns (uint256) {
        if ((block.number > lastRewardBlock) && (totalAmountStaked != 0)) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);

            uint256 tokenRewardForStaking = multiplier * rewardPerBlockForStaking;

            uint256 adjustedEndBlock = endBlock;
            uint256 adjustedCurrentPhase = currentPhase;

            // Check whether to adjust multipliers and reward per block
            while ((block.number > adjustedEndBlock) && (adjustedCurrentPhase < (NUMBER_PERIODS - 1))) {
                // Update current phase
                adjustedCurrentPhase++;

                // Update rewards per block
                uint256 adjustedRewardPerBlockForStaking = stakingPeriod[adjustedCurrentPhase].rewardPerBlockForStaking;

                // Calculate adjusted block number
                uint256 previousEndBlock = adjustedEndBlock;

                // Update end block
                adjustedEndBlock = previousEndBlock + stakingPeriod[adjustedCurrentPhase].periodLengthInBlock;

                // Calculate new multiplier
                uint256 newMultiplier = (block.number <= adjustedEndBlock)
                    ? (block.number - previousEndBlock)
                    : stakingPeriod[adjustedCurrentPhase].periodLengthInBlock;

                // Adjust token rewards for staking
                tokenRewardForStaking += (newMultiplier * adjustedRewardPerBlockForStaking);
            }

            uint256 adjustedTokenPerShare = accTokenPerShare +
                (tokenRewardForStaking * PRECISION_FACTOR) /
                totalAmountStaked;

            return (userInfo[user].amount * adjustedTokenPerShare) / PRECISION_FACTOR - userInfo[user].rewardDebt;
        } else {
            return (userInfo[user].amount * accTokenPerShare) / PRECISION_FACTOR - userInfo[user].rewardDebt;
        }
    }

    /**
     * @notice Update reward variables of the pool
     */
    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalAmountStaked == 0) {
            lastRewardBlock = uint40(block.number);
            return;
        }

        // Calculate multiplier
        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);

        // Calculate rewards for staking and others
        uint256 tokenRewardForStaking = multiplier * rewardPerBlockForStaking;
        uint256 tokenRewardForOthers = multiplier * rewardPerBlockForOthers;

        // Check whether to adjust multipliers and reward per block
        while ((block.number > endBlock) && (currentPhase < (NUMBER_PERIODS - 1))) {
            // Update rewards per block
            _updateRewardsPerBlock(endBlock);

            uint256 previousEndBlock = endBlock;

            // Adjust the end block
            endBlock += stakingPeriod[currentPhase].periodLengthInBlock;

            // Adjust multiplier to cover the missing periods with other lower inflation schedule
            uint256 newMultiplier = _getMultiplier(previousEndBlock, block.number);

            // Adjust token rewards
            tokenRewardForStaking += (newMultiplier * rewardPerBlockForStaking);
            tokenRewardForOthers += (newMultiplier * rewardPerBlockForOthers);
        }

        // Mint tokens only if token rewards for staking are not null
        if (tokenRewardForStaking > 0) {
            // It allows protection against potential issues to prevent funds from being locked
            bool mintStatus = looksRareToken.mint(address(this), tokenRewardForStaking);
            if (mintStatus) {
                uint256 newAccTokenPerShare = accTokenPerShare +
                    ((tokenRewardForStaking * PRECISION_FACTOR) / totalAmountStaked);
                if (newAccTokenPerShare > type(uint160).max) {
                    accTokenPerShare = type(uint160).max;
                } else {
                    accTokenPerShare = uint160(newAccTokenPerShare);
                }
            }

            looksRareToken.mint(tokenSplitter, tokenRewardForOthers);
        }

        // Update last reward block only if it wasn't updated after or at the end block
        if (lastRewardBlock <= endBlock) {
            lastRewardBlock = uint40(block.number);
        }
    }

    /**
     * @notice Update rewards per block
     * @dev Rewards are halved by 2 (for staking + others)
     */
    function _updateRewardsPerBlock(uint256 _newStartBlock) internal {
        // Update current phase
        currentPhase++;

        // Update rewards per block
        rewardPerBlockForStaking = stakingPeriod[currentPhase].rewardPerBlockForStaking;
        rewardPerBlockForOthers = stakingPeriod[currentPhase].rewardPerBlockForOthers;

        emit NewRewardsPerBlock(currentPhase, _newStartBlock, rewardPerBlockForStaking, rewardPerBlockForOthers);
    }

    /**
     * @notice Return reward multiplier over the given "from" to "to" block.
     * @param from block to start calculating reward
     * @param to block to finish calculating reward
     * @return the multiplier for the period
     */
    function _getMultiplier(uint256 from, uint256 to) internal view returns (uint256) {
        if (to <= endBlock) {
            return to - from;
        } else if (from >= endBlock) {
            return 0;
        } else {
            return endBlock - from;
        }
    }
}