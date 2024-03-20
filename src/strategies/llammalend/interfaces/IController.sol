// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

interface IController {
    function check_lock() external view returns (bool);
}
