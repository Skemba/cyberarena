// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesCompUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract CyberArenaStaking is ERC20VotesCompUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev Staking token
    IERC20Upgradeable public stakingToken;

    /// @dev Info about each stake by user address
    mapping(address => Stake[]) public stakers;

    /// @dev Penalty days value
    uint16 public penaltyDays;

    /// @dev Penalty base points value
    uint16 public penaltyBP;

    /// @dev The address to which the penalty tokens will be transferred
    address public treasury;

    /// @dev Total shares
    uint192 public totalShares;

    struct Stake {
        bool unstaked;
        uint128 amount;
        uint48 stakedTimestamp;
        uint16 penaltyDays;
        uint16 penaltyBP;
        uint192 shares;
    }

    /**
     * @notice Initializer
     * @param _stakingToken Staking token address
     * @param _penaltyDays Penalty days value
     * @param _penaltyBP Penalty base points value
     * @param _treasury The address to which the penalty tokens will be transferred
     */
    function initialize(
        IERC20Upgradeable _stakingToken,
        uint16 _penaltyDays,
        uint16 _penaltyBP,
        address _treasury
    ) external virtual initializer {
        __ERC20_init("Staked CAT", "stCAT");
        __ERC20Permit_init("Staked CAT");
        __Ownable_init();
        __ReentrancyGuard_init();

        require(address(_stakingToken) != address(0), "CyberArenaStaking: staking token is the zero address");
        require(_treasury != address(0), "CyberArenaStaking: treasury is the zero address");

        stakingToken = _stakingToken;
        penaltyDays = _penaltyDays;
        penaltyBP = _penaltyBP;
        treasury = _treasury;
    }

    /**
     * @notice Stake staking tokens
     * @param _amount amount to stake
     */
    function stake(uint128 _amount) external nonReentrant {
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        _mint(msg.sender, _amount);

        totalShares += _amount;
        stakers[msg.sender].push(Stake(
            false,
            _amount,
            uint48(getCurrentTime()),
            penaltyDays,
            penaltyBP,
            _amount
        ));
    }

    /**
     * @notice Unstake staking tokens
     * @notice If penalty period is not over grab penalty
     * @param _stakeIndex Stake index in array of user's stakes
     */
    function unstake(uint256 _stakeIndex) external nonReentrant {
        require(_stakeIndex < stakers[msg.sender].length, "CyberArenaStaking: invalid index");
        Stake storage stakeRef = stakers[msg.sender][_stakeIndex];
        require(!stakeRef.unstaked, "CyberArenaStaking: unstaked already");

        _burn(msg.sender, stakeRef.amount);
        totalShares -= stakeRef.shares;
        stakeRef.unstaked = true;

        // pays a penalty if unstakes during the penalty period
        uint256 penaltyAmount = 0;
        if (stakeRef.stakedTimestamp + uint48(stakeRef.penaltyDays) * 86400 > getCurrentTime()) {
            penaltyAmount = stakeRef.amount * stakeRef.penaltyBP / 1e4;
            stakingToken.safeTransfer(treasury, penaltyAmount);
        }

        stakingToken.safeTransfer(msg.sender, stakeRef.amount - penaltyAmount);
    }

    // ** ONLY OWNER **

    /**
     * @notice Set a new penalty days value
     * @param _penaltyDays New penalty days value
     */
    function setPenaltyDays(uint16 _penaltyDays) external onlyOwner {
        penaltyDays = _penaltyDays;
    }

    /**
     * @notice Set a new penalty base points value
     * @param _penaltyBP New penalty base points value
     */
    function setPenaltyBP(uint16 _penaltyBP) external onlyOwner {
        penaltyBP = _penaltyBP;
    }

    /**
     * @notice Set a new penalty treasury
     * @param _treasury New treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        // require(_treasury != address(0), "CyberArenaStaking: treasury is the zero address");
        treasury = _treasury;
    }

    // ** INTERNAL **

    /// @dev disable transfers
    function _transfer(address _from, address _to, uint256 _amount) internal override {
        revert("CyberArenaStaking: NON_TRANSFERABLE");
    }

    function getCurrentTime()
        internal
        virtual
        view
        returns(uint256){
        return block.timestamp;
    }
}