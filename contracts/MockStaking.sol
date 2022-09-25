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

    constructor() CyberArenaStaking(){
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