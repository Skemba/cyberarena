// contracts/Staking.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./Staking.sol";

/**
 * @title MockStaking
 * WARNING: use only for testing and debugging purpose
 */
contract MockStaking is CyberArenaStaking{

    uint256 mockTime = 0;

    constructor(        IERC20 _stakingToken,
        uint16 _penaltyDays,
        uint16 _penaltyBP,
        address _treasury) CyberArenaStaking(_stakingToken, _penaltyDays, _penaltyBP, _treasury) {
    }

    function setCurrentTime(uint256 _time)
        external{
        mockTime = _time;
    }

    function getCurrentTime()
        internal
        virtual
        override
        view
        returns(uint256){
        return mockTime;
    }
}