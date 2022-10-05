// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20VotesComp.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CyberArenaStaking is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @dev Max penalty days
    uint256 private constant PENALTY_DAYS_LIMIT = 90;

    /// @dev Max penalty base points
    uint256 private constant PENALTY_BP_LIMIT = 1e4;

    /// @dev Staking token
    IERC20 public stakingToken;

    /// @dev Info about each stake by user address
    mapping(address => Stake) public stakers;

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

    event SetPenaltyDays(uint16 penaltyDays);
    event SetPenaltyBP(uint16 penaltyBP);
    event SetTreasury(address treasury);

    /**
     * @notice Initializer
     * @param _stakingToken Staking token address
     * @param _penaltyDays Penalty days value
     * @param _penaltyBP Penalty base points value
     * @param _treasury The address to which the penalty tokens will be transferred
     */
    constructor(
        IERC20 _stakingToken,
        uint16 _penaltyDays,
        uint16 _penaltyBP,
        address _treasury
    ) 
        ERC20("Staked CAT", "stCAT")
    {

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
        Stake storage stakeRef = stakers[msg.sender];
        require(stakeRef.stakedTimestamp == 0, "CyberArenaStaking: already staked");
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        _mint(msg.sender, _amount);

        totalShares += _amount;
        stakers[msg.sender] = Stake(
            false,
            _amount,
            uint48(getCurrentTime()),
            penaltyDays,
            penaltyBP,
            _amount
        );
    }

    /**
     * @notice Unstake staking tokens
     * @notice If penalty period is not over grab penalty
     */
    function unstake() external nonReentrant {
        Stake storage stakeRef = stakers[msg.sender];
        require(stakeRef.stakedTimestamp != 0, "CyberArenaStaking: nothing is staked");
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
        require(_penaltyDays <= PENALTY_DAYS_LIMIT, "CyberArenaStaking: penalty days exceeds limit");
        penaltyDays = _penaltyDays;
        emit SetPenaltyDays(_penaltyDays);
    }

    /**
     * @notice Set a new penalty base points value
     * @param _penaltyBP New penalty base points value
     */
    function setPenaltyBP(uint16 _penaltyBP) external onlyOwner {
        require(_penaltyBP <= PENALTY_BP_LIMIT, "CyberArenaStaking: penalty BP exceeds limit");
        penaltyBP = _penaltyBP;
        emit SetPenaltyBP(_penaltyBP);
    }

    /**
     * @notice Set a new penalty treasury
     * @param _treasury New treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "CyberArenaStaking: treasury is the zero address");
        treasury = _treasury;
         emit SetTreasury(_treasury);
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