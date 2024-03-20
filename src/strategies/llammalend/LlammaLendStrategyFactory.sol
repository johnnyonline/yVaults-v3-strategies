// // SPDX-License-Identifier: AGPL-3.0
// pragma solidity 0.8.18;

// import {ISiloRepository} from "@silo/interfaces/ISiloRepository.sol";
// import {Ping} from "@silo/lib/Ping.sol";

// import {IStrategyInterface} from "../../interfaces/IStrategyInterface.sol";

// import {SiloStrategy, IAaveIncentivesController, ISilo} from "./SiloStrategy.sol";

// /**
//  * @title LlammaLendStrategyFactory
//  * @author johnnyonline
//  * @notice Factory for creating Llamalend strategies
//  */
// contract LlammaLendStrategyFactory {
//     /**
//      * @notice Emitted when a new Silo strategy is deployed.
//      */
//     event StrategyDeployed(
//         address _management,
//         address strategy,
//         address silo,
//         address share,
//         address indexed strategyAsset,
//         address rewardToken,
//         address incentivesController,
//         string name
//     );

//     /**
//      * @dev The Silo repository contract.
//      */
//     ISiloRepository public immutable repository;

//     /**
//      * @notice Used to initialize the strategy factory on deployment.
//      * @param _repository Address of the Silo repository.
//      */
//     constructor(ISiloRepository _repository) {
//         require(
//             Ping.pong(_repository.siloRepositoryPing),
//             "invalid silo repository"
//         );

//         repository = _repository;
//     }

//     /**
//      * @notice Used to deploy a new Silo strategy.
//      * @param _management Address of the management account.
//      * @param _siloAsset Address of the Silo asset. Used to get the Silo address.
//      * @param _strategyAsset Address of the underlying strategy asset.
//      * @param _incentivesController Address of the incentives controller that pays the reward token.
//      * @param _name Name the strategy will use.
//      */
//     function deploySiloStrategy(
//         address _management,
//         address _siloAsset,
//         address _strategyAsset,
//         address _incentivesController,
//         string memory _name
//     ) external returns (address _strategy) {
//         require(_management != address(0), "invalid management");

//         address _silo = repository.getSilo(_siloAsset);
//         address _share = address(
//             ISilo(_silo).assetStorage(_strategyAsset).collateralToken
//         );
//         require(_share != address(0), "wrong silo");

//         address _rewardToken = address(0);
//         if (_incentivesController != address(0)) {
//             _rewardToken = IAaveIncentivesController(_incentivesController)
//                 .REWARD_TOKEN();
//         }

//         _strategy = address(
//             new SiloStrategy(
//                 _silo,
//                 _share,
//                 _strategyAsset,
//                 _rewardToken,
//                 _incentivesController,
//                 _name
//             )
//         );

//         IStrategyInterface(_strategy).setPendingManagement(_management);

//         emit StrategyDeployed(
//             _management,
//             _strategy,
//             _silo,
//             _share,
//             _strategyAsset,
//             _rewardToken,
//             _incentivesController,
//             _name
//         );
//     }
// }
