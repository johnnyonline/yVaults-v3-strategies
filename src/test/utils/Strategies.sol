// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import {ExtendedTest} from "./ExtendedTest.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {ISiloRepository} from "@silo/interfaces/ISiloRepository.sol";
import {ISilo} from "@silo/interfaces/ISilo.sol";

import {IStrategyInterface} from "../../interfaces/IStrategyInterface.sol";

import {SiloStrategyFactory, SiloStrategy} from "../../strategies/silo/SiloStrategyFactory.sol";

contract Strategies is ExtendedTest {
    address private constant _crvUSDYFISilo =
        0xb0823c25cDF531a58e581eE14f160c290fef5722;
    address private constant _siloRepository =
        0xBCd67f35c7A2F212db0AD7f68fC773b5aC15377c;
    address private constant _crvUSD =
        0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E;
    address private constant _incentivesController =
        0x361384A0d755f972E5Eea26e4F4efBAf976B6461;
    address private constant _crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address private constant _yfi = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;

    address private _borrower = address(420);

    /*//////////////////////////////////////////////////////////////
                        GENERAL STRATEGY HELPERS
    //////////////////////////////////////////////////////////////*/

    function _setUpStrategy() internal returns (address) {
        return _setUpSiloStrategy();
    }

    function _earnInterest() internal {
        _earnSiloInterest();
    }

    function _testSetupStrategyOK(address strategy_) internal {
        SiloStrategy _strategy = SiloStrategy(strategy_);
        assertEq(
            address(_strategy.incentivesController()),
            _incentivesController,
            "!incentivesController"
        );
        assertEq(address(_strategy.silo()), _crvUSDYFISilo, "!silo");
        assertEq(
            address(_strategy.share()),
            address(_strategy.silo().assetStorage(_crvUSD).collateralToken),
            "!share"
        );
        assertEq(
            IStrategyInterface(address(_strategy)).performanceFeeRecipient(),
            performanceFeeRecipient,
            "!performanceFeeRecipient"
        );
        assertEq(
            IStrategyInterface(address(_strategy)).performanceFee(),
            1_000,
            "!performanceFee"
        );
    }

    function _customStrategyTest(address strategy_) internal {
        _testSiloNoLiquidity(strategy_);
    }

    /*//////////////////////////////////////////////////////////////
                    STRATEGY SPECIFIC HELPERS - SILO
    //////////////////////////////////////////////////////////////*/

    function _setUpSiloStrategy() private returns (address _strategy) {
        vm.expectRevert("invalid silo repository");
        new SiloStrategyFactory(
            ISiloRepository(address(0)),
            management,
            performanceFeeRecipient
        );

        SiloStrategyFactory factory = new SiloStrategyFactory(
            ISiloRepository(_siloRepository),
            management,
            performanceFeeRecipient
        );

        vm.expectRevert("wrong silo");
        factory.deploySiloStrategy(
            management,
            _crv,
            _yfi,
            _incentivesController,
            "crvUSD/YFI SiloLlamaStrategy"
        );

        vm.expectRevert("wrong silo");
        factory.deploySiloStrategy(
            management,
            _yfi,
            _crv,
            _incentivesController,
            "crvUSD/YFI SiloLlamaStrategy"
        );

        _strategy = address(factory.deploySiloStrategy(
            management,
            _yfi,
            _crvUSD,
            _incentivesController,
            "crvUSD/YFI SiloLlamaStrategy"
        ));
    }

    function _earnSiloInterest() private {
        ISilo(_crvUSDYFISilo).accrueInterest(_crvUSD);
    }

    function _testSiloNoLiquidity(address strategy_) private {
        SiloStrategy _strategy = SiloStrategy(strategy_);
        ISilo _silo = _strategy.silo();

        uint256 _amount = 1_000_000_000 * 1e18;
        deal(_yfi, _borrower, _amount);

        vm.startPrank(_borrower);

        ERC20(_yfi).approve(address(_silo), _amount);

        _silo.deposit(
            _yfi,
            _amount,
            true // _collateralOnly
        );

        _silo.borrow(
            _crvUSD,
            ISilo(_crvUSDYFISilo).liquidity(_crvUSD) // borrow all
        );

        assertEq(_strategy.availableWithdrawLimit(address(0)), 0, "!availableWithdrawLimit");
    }
}
