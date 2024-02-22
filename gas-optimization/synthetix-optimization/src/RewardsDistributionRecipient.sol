pragma solidity 0.8.20;

// Inheritance
import "./Owned.sol";

// https://docs.synthetix.io/contracts/source/contracts/rewardsdistributionrecipient
abstract contract RewardsDistributionRecipient is Owned {
    address internal _rewardsDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardsDistribution() {
        require(msg.sender == _rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }

    function setRewardsDistribution(address rewardsDistribution_) external onlyOwner {
        _rewardsDistribution = rewardsDistribution_;
    }
}