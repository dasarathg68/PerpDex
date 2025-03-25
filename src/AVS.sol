// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AVS is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Constants
    uint256 public constant MINIMUM_STAKE = 1000 ether; // 1000 ETH
    uint256 public constant VALIDATOR_REWARD_BPS = 100; // 1%
    uint256 public constant MAX_BPS = 10000;
    uint256 public constant MIN_VALIDATORS = 3;
    uint256 public constant MAX_VALIDATORS = 100;

    // State variables
    IERC20 public immutable stakingToken;
    uint256 public totalStaked;
    uint256 public activeValidatorCount;
    uint256 public nextValidatorId;

    struct Validator {
        address validator;
        uint256 stake;
        bool isActive;
        uint256 lastValidation;
        uint256 totalRewards;
    }

    mapping(uint256 => Validator) public validators;
    mapping(address => uint256) public validatorIds;
    mapping(address => bool) public isValidator;

    // Events
    event ValidatorRegistered(uint256 indexed validatorId, address indexed validator, uint256 stake);
    event ValidatorRemoved(uint256 indexed validatorId, address indexed validator);
    event StakeDeposited(uint256 indexed validatorId, uint256 amount);
    event StakeWithdrawn(uint256 indexed validatorId, uint256 amount);
    event RewardsDistributed(uint256 indexed validatorId, uint256 amount);

    constructor(address _stakingToken) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
    }

    function registerValidator() external nonReentrant {
        require(!isValidator[msg.sender], "Already registered");
        require(activeValidatorCount < MAX_VALIDATORS, "Max validators reached");

        uint256 validatorId = nextValidatorId++;
        validators[validatorId] = Validator({
            validator: msg.sender,
            stake: 0,
            isActive: false,
            lastValidation: 0,
            totalRewards: 0
        });

        validatorIds[msg.sender] = validatorId;
        isValidator[msg.sender] = true;

        emit ValidatorRegistered(validatorId, msg.sender, 0);
    }

    function depositStake(uint256 amount) external nonReentrant {
        require(isValidator[msg.sender], "Not registered");
        require(amount > 0, "Invalid amount");

        uint256 validatorId = validatorIds[msg.sender];
        Validator storage validator = validators[validatorId];

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        validator.stake += amount;
        totalStaked += amount;

        if (!validator.isActive && validator.stake >= MINIMUM_STAKE) {
            validator.isActive = true;
            activeValidatorCount++;
        }

        emit StakeDeposited(validatorId, amount);
    }

    function withdrawStake(uint256 amount) external nonReentrant {
        require(isValidator[msg.sender], "Not registered");
        require(amount > 0, "Invalid amount");

        uint256 validatorId = validatorIds[msg.sender];
        Validator storage validator = validators[validatorId];
        require(validator.stake >= amount, "Insufficient stake");

        if (validator.isActive && (validator.stake - amount) < MINIMUM_STAKE) {
            validator.isActive = false;
            activeValidatorCount--;
        }

        validator.stake -= amount;
        totalStaked -= amount;

        stakingToken.safeTransfer(msg.sender, amount);
        emit StakeWithdrawn(validatorId, amount);
    }

    function validateTrade(uint256 tradeId, bytes[] calldata signatures) external view returns (bool) {
        require(signatures.length >= MIN_VALIDATORS, "Insufficient signatures");
        require(activeValidatorCount >= MIN_VALIDATORS, "Insufficient validators");

        // TODO: Implement signature verification logic
        // This would involve:
        // 1. Verifying each signature is from an active validator
        // 2. Ensuring enough validators have signed
        // 3. Checking signature timestamps are recent
        // 4. Verifying the trade data matches the signatures

        return true;
    }

    function distributeRewards(uint256 validatorId, uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");
        Validator storage validator = validators[validatorId];
        require(validator.isActive, "Validator not active");

        uint256 reward = (amount * VALIDATOR_REWARD_BPS) / MAX_BPS;
        validator.totalRewards += reward;

        stakingToken.safeTransfer(validator.validator, reward);
        emit RewardsDistributed(validatorId, reward);
    }

    function removeValidator(uint256 validatorId) external onlyOwner {
        Validator storage validator = validators[validatorId];
        require(validator.validator != address(0), "Invalid validator");

        if (validator.isActive) {
            validator.isActive = false;
            activeValidatorCount--;
        }

        isValidator[validator.validator] = false;
        delete validatorIds[validator.validator];

        emit ValidatorRemoved(validatorId, validator.validator);
    }

    function getValidator(uint256 validatorId) external view returns (Validator memory) {
        return validators[validatorId];
    }

    function getValidatorByAddress(address validator) external view returns (Validator memory) {
        return validators[validatorIds[validator]];
    }
} 