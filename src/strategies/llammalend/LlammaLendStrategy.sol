// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import {BaseHealthCheck, ERC20} from "@periphery/Bases/HealthCheck/BaseHealthCheck.sol";
import {TradeFactorySwapper} from "@periphery/swappers/TradeFactorySwapper.sol";

import {IController} from "./interfaces/IController.sol";
import {ILiquidityGauge} from "./interfaces/ILiquidityGauge.sol";

/**
 * The `TokenizedStrategy` variable can be used to retrieve the strategies
 * specific storage data your contract.
 *
 *       i.e. uint256 totalAssets = TokenizedStrategy.totalAssets()
 *
 * This can not be used for write functions. Any TokenizedStrategy
 * variables that need to be updated post deployment will need to
 * come from an external call from the strategies specific `management`.
 */

// NOTE: To implement permissioned functions you can use the onlyManagement, onlyEmergencyAuthorized and onlyKeepers modifiers

/**
 * @title LlammaLendStrategy
 * @author johnnyonline
 * @notice A strategy that provides liquidity to a Llammalend Vault, deposits LP tokens in the respective liquidity gauge
            and harvests incentives.
 */
contract LlammaLendStrategy is BaseHealthCheck, TradeFactorySwapper {

    using SafeERC20 for ERC20;

    /**
     * @dev The LlamaLend Vault the strategy is using.
     */
    IERC4626 public immutable vault;

    /**
     * @dev The LlamaLend Controller the strategy is using.
     */
    IController public immutable controller;

    /**
     * @dev The LlamaLend Liquidity Gauge the LlammaLend Vault is using.
     */
    ILiquidityGauge public immutable liquidityGauge;

    /**
     * @notice Used to initialize the strategy on deployment.
     * @param _asset Address of the underlying asset.
     * @param _vault Address of the LlamaLend Vault.
     * @param _controller Address of the LlamaLend controller.
     * @param _name Name the strategy will use.
     */
    constructor(
        address _asset,
        address _vault,
        address _controller,
        address _liquidityGauge,
        string memory _name
    ) BaseHealthCheck(_asset, _name) {
        vault = IERC4626(_vault);
        controller = IController(_controller);
        liquidityGauge = ILiquidityGauge(_liquidityGauge);

        ERC20(_asset).forceApprove(address(_vault), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                        MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setTradeFactory(
        address _tradeFactory,
        address _tokenTo
    ) external onlyManagement {
        _setTradeFactory(_tradeFactory, _tokenTo);
    }

    function addTokens(
        address[] memory _from,
        address[] memory _to
    ) external onlyManagement {
        _addTokens(_from, _to);
    }

    /*//////////////////////////////////////////////////////////////
                NEEDED TO BE OVERRIDDEN BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the max amount of `asset` that can be withdrawn.
     * @dev Defaults to an unlimited amount for any address. But can
     * be overridden by strategists.
     *
     * This function will be called before any withdraw or redeem to enforce
     * any limits desired by the strategist. This can be used for illiquid
     * or sandwichable strategies.
     *
     *   EX:
     *       return asset.balanceOf(address(this));;
     *
     * This does not need to take into account the `_owner`'s share balance
     * or conversion rates from shares to assets.
     *
     * @param . The address that is withdrawing from the strategy.
     * @return . The available amount that can be withdrawn in terms of `asset`
     *
     */
    function availableWithdrawLimit(
        address // _owner
    ) public view override returns (uint256) {
        controller.check_lock();
        return asset.balanceOf(address(controller));
    }

    /**
     * @dev Can deploy up to '_amount' of 'asset' in the yield source.
     *
     * This function is called at the end of a {deposit} or {mint}
     * call. Meaning that unless a whitelist is implemented it will
     * be entirely permissionless and thus can be sandwiched or otherwise
     * manipulated.
     *
     * @param _amount The amount of 'asset' that the strategy can attempt
     * to deposit in the yield source.
     */
    function _deployFunds(uint256 _amount) internal override {
        if (!TokenizedStrategy.isShutdown()) {
            vault.deposit(_amount, address(this));
        }
    }

    /**
     * @dev Should attempt to free the '_amount' of 'asset'.
     *
     * NOTE: The amount of 'asset' that is already loose has already
     * been accounted for.
     *
     * This function is called during {withdraw} and {redeem} calls.
     * Meaning that unless a whitelist is implemented it will be
     * entirely permissionless and thus can be sandwiched or otherwise
     * manipulated.
     *
     * Should not rely on asset.balanceOf(address(this)) calls other than
     * for diff accounting purposes.
     *
     * Any difference between `_amount` and what is actually freed will be
     * counted as a loss and passed on to the withdrawer. This means
     * care should be taken in times of illiquidity. It may be better to revert
     * if withdraws are simply illiquid so not to realize incorrect losses.
     *
     * @param _amount, The amount of 'asset' to be freed.
     */
    function _freeFunds(uint256 _amount) internal override {
        vault.withdraw(_amount, address(this), address(this));
    }

    /**
     * @dev Internal function to harvest all rewards, redeploy any idle
     * funds and return an accurate accounting of all funds currently
     * held by the Strategy.
     *
     * This should do any needed harvesting, rewards selling, accrual,
     * redepositing etc. to get the most accurate view of current assets.
     *
     * NOTE: All applicable assets including loose assets should be
     * accounted for in this function.
     *
     * Care should be taken when relying on oracles or swap values rather
     * than actual amounts as all Strategy profit/loss accounting will
     * be done based on this returned value.
     *
     * This can still be called post a shutdown, a strategist can check
     * `TokenizedStrategy.isShutdown()` to decide if funds should be
     * redeployed or simply realize any profits/losses.
     *
     * @return _totalAssets A trusted and accurate account for the total
     * amount of 'asset' the strategy currently holds including idle funds.
     */
    function _harvestAndReport()
        internal
        override
        returns (uint256 _totalAssets)
    {
        // Only harvest and redeploy if the strategy is not shutdown.
        if (!TokenizedStrategy.isShutdown()) {

            // Check how much we can re-deploy into the yield source.
            uint256 toDeploy = asset.balanceOf(address(this));
            // If greater than 0.
            if (toDeploy > 0)
                // Deposit the sold amount back into the yield source.
                _deployFunds(toDeploy);

            // Check how much we can re-deploy into the liquidity gauge.
            uint256 toDeployInLiquidityGauge = vault.balanceOf(address(this));
            if (toDeployInLiquidityGauge > 0 && address(liquidityGauge) != address(0)) 
                // Deposit the LP tokens in the liquidity gauge.
                liquidityGauge.deposit(toDeployInLiquidityGauge, address(this));
        }

        // Return full balance no matter what.
        uint256 _redeemableForShares = vault.previewRedeem(
            vault.balanceOf(address(this)) + liquidityGauge.balanceOf(address(this))
        );

        _totalAssets = _redeemableForShares + asset.balanceOf(address(this));
    }

    function _claimRewards() internal override {
        if (address(liquidityGauge) != address(0)) {
            bool _shouldClaim = false;
            address[] memory rewardTokens_ = rewardTokens();
            for (uint256 i; i < rewardTokens_.length; ++i) {
                if (liquidityGauge.claimableReward(address(this), rewardTokens_[i]) > 0) {
                    _shouldClaim = true;
                    break;
                }
            }

            if (_shouldClaim) 
                liquidityGauge.claimRewards(address(this), address(this));
        }
    }

    /*//////////////////////////////////////////////////////////////
                    OPTIONAL TO OVERRIDE BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Optional function for strategist to override that can
     *  be called in between reports.
     *
     * If '_tend' is used tendTrigger() will also need to be overridden.
     *
     * This call can only be called by a permissioned role so may be
     * through protected relays.
     *
     * This can be used to harvest and compound rewards, deposit idle funds,
     * perform needed position maintenance or anything else that doesn't need
     * a full report for.
     *
     *   EX: A strategy that can not deposit funds without getting
     *       sandwiched can use the tend when a certain threshold
     *       of idle to totalAssets has been reached.
     *
     * This will have no effect on PPS of the strategy till report() is called.
     *
     * @param _totalIdle The current amount of idle funds that are available to deploy.
     *
    function _tend(uint256 _totalIdle) internal override {}
    */

    /**
     * @dev Optional trigger to override if tend() will be used by the strategy.
     * This must be implemented if the strategy hopes to invoke _tend().
     *
     * @return . Should return true if tend() should be called by keeper or false if not.
     *
    function _tendTrigger() internal view override returns (bool) {}
    */

    /**
     * @notice Gets the max amount of `asset` that an address can deposit.
     * @dev Defaults to an unlimited amount for any address. But can
     * be overridden by strategists.
     *
     * This function will be called before any deposit or mints to enforce
     * any limits desired by the strategist. This can be used for either a
     * traditional deposit limit or for implementing a whitelist etc.
     *
     *   EX:
     *      if(isAllowed[_owner]) return super.availableDepositLimit(_owner);
     *
     * This does not need to take into account any conversion rates
     * from shares to assets. But should know that any non max uint256
     * amounts may be converted to shares. So it is recommended to keep
     * custom amounts low enough as not to cause overflow when multiplied
     * by `totalSupply`.
     *
     * @param . The address that is depositing into the strategy.
     * @return . The available amount the `_owner` can deposit in terms of `asset`
     *
    function availableDepositLimit(
        address _owner
    ) public view override returns (uint256) {
        TODO: If desired Implement deposit limit logic and any needed state variables .

        EX:
            uint256 totalAssets = TokenizedStrategy.totalAssets();
            return totalAssets >= depositLimit ? 0 : depositLimit - totalAssets;
    }
    */

    /**
     * @dev Optional function for a strategist to override that will
     * allow management to manually withdraw deployed funds from the
     * yield source if a strategy is shutdown.
     *
     * This should attempt to free `_amount`, noting that `_amount` may
     * be more than is currently deployed.
     *
     * NOTE: This will not realize any profits or losses. A separate
     * {report} will be needed in order to record any profit/loss. If
     * a report may need to be called after a shutdown it is important
     * to check if the strategy is shutdown during {_harvestAndReport}
     * so that it does not simply re-deploy all funds that had been freed.
     *
     * EX:
     *   if(freeAsset > 0 && !TokenizedStrategy.isShutdown()) {
     *       depositFunds...
     *    }
     *
     * @param _amount The amount of asset to attempt to free.
     *
    function _emergencyWithdraw(uint256 _amount) internal override {
        TODO: If desired implement simple logic to free deployed funds.

        EX:
            _amount = min(_amount, aToken.balanceOf(address(this)));
            _freeFunds(_amount);
    }

    */
}
