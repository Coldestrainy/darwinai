// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract AgentIDNFT is ERC721 {
    uint256 public nextTokenId;
    address public treasury;

    constructor(address _treasury) ERC721("DarwinAgentID", "DAID") {
        treasury = _treasury;
    }

    function mintAgentID() external {
        _safeMint(msg.sender, nextTokenId);
        nextTokenId++;
    }
}
