// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface ITokenDistributor {
    /**
     * @notice Deposit staked tokens and compounds pending rewards
     * @param amount amount to deposit (in LOOKS)
     */
    function deposit(uint256 amount) external;

    /**
     * @notice Compound based on pending rewards
     */
    function harvestAndCompound() external;

    /**
     * @notice Update pool rewards
     */
    function updatePool() external;

    /**
     * @notice Withdraw staked tokens and compound pending rewards
     * @param amount amount to withdraw
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice Withdraw all staked tokens and collect tokens
     */
    function withdrawAll() external;
}
