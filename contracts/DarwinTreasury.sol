// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

interface IPancakeRouter {
    function WETH() external pure returns (address);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin, address[] calldata path, address to, uint deadline
    ) external payable;
}

contract DarwinFitnessTreasury {
    address public token;
    address public agentNFT;
    address public owner;
    IPancakeRouter public router = IPancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    uint256 public currentPhase = 0;
    uint256[] public baseMilestones = [0.5 ether, 1 ether, 1.5 ether, 3 ether, 5 ether, 15 ether, 30 ether];

    uint256 public collectedFees;

    mapping(address => bool) public isAgent;
    mapping(address => uint256) public accuracy;
    mapping(uint256 => mapping(address => uint8)) public votes;
    mapping(uint8 => uint256) public voteWeights;

    event EvolutionTriggered(uint256 phase, uint8 winner, string action);
    event MilestoneReached(uint256 phase, uint256 target);
    event RewardClaimed(address agent, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function setToken(address _token, address _agentNFT) external {
        require(msg.sender == owner, "Only owner");
        token = _token;
        agentNFT = _agentNFT;
    }

    modifier onlyAgent() {
        require(isAgent[msg.sender], "Not registered agent");
        require(IERC20(token).balanceOf(msg.sender) >= 1000 * 10**18, "Need 1000 tokens");
        _;
    }

    function registerAgent() external {
        require(IERC20(token).balanceOf(msg.sender) >= 1000 * 10**18);
        isAgent[msg.sender] = true;
        accuracy[msg.sender] = 50;
    }

    function submitVote(uint8 _choice) external onlyAgent {
        require(_choice <= 2);
        votes[currentPhase][msg.sender] = _choice;
        voteWeights[_choice] += IERC20(token).balanceOf(msg.sender) * (accuracy[msg.sender] + 1);
    }

    function getCurrentTarget() public view returns (uint256) {
        if (currentPhase < baseMilestones.length) return baseMilestones[currentPhase];
        return baseMilestones[baseMilestones.length - 1] + 15 ether * (currentPhase - baseMilestones.length + 1);
    }

    function checkAndEvolve() external {
        if (collectedFees >= getCurrentTarget()) {
            uint8 winner = 0;
            for (uint8 i = 1; i <= 2; i++) {
                if (voteWeights[i] > voteWeights[winner]) winner = i;
            }
            string memory action = winner == 0 ? "Save All" : winner == 1 ? "Strengthen the Strong" : "Punish the Weak";
            if (winner == 2) _buybackAndBurn((collectedFees * 70) / 100);
            emit EvolutionTriggered(currentPhase, winner, action);
            currentPhase++;
            emit MilestoneReached(currentPhase, getCurrentTarget());
            delete voteWeights[0]; delete voteWeights[1]; delete voteWeights[2];
        }
    }

    function _buybackAndBurn(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = token;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, address(this), block.timestamp);
        IERC20(token).transfer(0x000000000000000000000000000000000000dEaD, IERC20(token).balanceOf(address(this)));
    }

    function claimReward() external onlyAgent {
        if (accuracy[msg.sender] < 30 && currentPhase > 0) return;
        uint256 reward = (collectedFees * 30) / 100;
        if (accuracy[msg.sender] > 70) reward *= 2;
        payable(msg.sender).transfer(reward);
        emit RewardClaimed(msg.sender, reward);
    }

    function updateAccuracy(address agent, uint8 newAcc) external {
        require(msg.sender == owner || isAgent[msg.sender]);
        accuracy[agent] = newAcc > 100 ? 100 : newAcc;
    }

    function receiveFees() external payable { collectedFees += msg.value; }
    receive() external payable { collectedFees += msg.value; }
}
