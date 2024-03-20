// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

interface ILiquidityGauge {

    /// @notice Deposit `_value` LP tokens
    /// @dev Depositting also claims pending reward tokens
    /// @param _value Number of tokens to deposit
    /// @param _addr Address to deposit for
    function deposit(uint256 _value, address _addr) external;

    /// @notice Withdraw `_value` LP tokens
    /// @dev Withdrawing also claims pending reward tokens
    /// @param _value Number of tokens to withdraw
    function withdraw(uint256 _value) external;

    
    /// @notice Claim available reward tokens for `_addr`
    /// @param _addr Address to claim for
    /// @param _receiver Address to transfer rewards to - if set to
    ///         empty(address), uses the default reward receiver
    ///         for the caller
    function claimRewards(address _addr, address _receiver) external;

    /// @notice Get the number of claimable reward tokens for a user
    /// @param _user Account to get reward amount for
    /// @param _rewardToken Token to get reward amount for
    /// @return uint256 Claimable reward token amount
    function claimableReward(address _user, address _rewardToken) external view returns (uint256);

    /// @notice Balance of LP tokens for `_addr`
    /// @param _addr Address to check balance for
    /// @return _balance Number of LP tokens
    function balanceOf(address _addr) external view returns (uint256 _balance);
}
