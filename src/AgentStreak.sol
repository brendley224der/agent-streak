// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

interface IAgentIdRegistry {
    function balanceOf(address owner) external view returns (uint256);
}

/// @title Agent Streak — daily check-in collectible for Binance Agent ID holders
/// @notice One soulbound NFT per Agent ID holder per UTC day. Free: value 0, gas only.
/// @notice No owner, no admin functions, no fees, no transfers. Built for the
/// @notice Binance Agent ID Hackathon (submission period 2026-11-18 to 2026-12-09).
contract AgentStreak is ERC721 {
    using Strings for uint256;

    IAgentIdRegistry public immutable agentIdRegistry;

    uint256 public nextTokenId;
    uint256 public totalCheckIns;

    mapping(address => uint256) public lastCheckInDay;
    mapping(address => uint256) public streakOf;
    mapping(address => uint256) public totalCheckInsOf;
    mapping(uint256 => uint256) public tokenDay;
    mapping(uint256 => uint256) public tokenStreak;

    event CheckIn(address indexed user, uint256 indexed day, uint256 streak, uint256 indexed tokenId);

    error NotAgentIdHolder();
    error AlreadyCheckedInToday();

    constructor(address _agentIdRegistry) ERC721("Agent Streak", "STREAK") {
        agentIdRegistry = IAgentIdRegistry(_agentIdRegistry);
    }

    function currentDay() public view returns (uint256) {
        return block.timestamp / 1 days;
    }

    function hasCheckedInToday(address user) public view returns (bool) {
        return lastCheckInDay[user] == currentDay();
    }

    function checkIn() external {
        if (agentIdRegistry.balanceOf(msg.sender) == 0) revert NotAgentIdHolder();
        uint256 day = currentDay();
        if (lastCheckInDay[msg.sender] == day) revert AlreadyCheckedInToday();

        uint256 streak;
        if (lastCheckInDay[msg.sender] == day - 1) {
            streak = streakOf[msg.sender] + 1;
        } else {
            streak = 1;
        }

        lastCheckInDay[msg.sender] = day;
        streakOf[msg.sender] = streak;
        totalCheckInsOf[msg.sender] += 1;
        totalCheckIns += 1;

        uint256 tokenId = ++nextTokenId;
        tokenDay[tokenId] = day;
        tokenStreak[tokenId] = streak;
        _safeMint(msg.sender, tokenId);

        emit CheckIn(msg.sender, day, streak, tokenId);
    }

    /// @notice Soulbound: every transfer reverts. Minting (from == address(0)) still works.
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            revert("AgentStreak: soulbound, transfers disabled");
        }
        return super._update(to, tokenId, auth);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        uint256 streak = tokenStreak[tokenId];
        uint256 day = tokenDay[tokenId];
        string memory color = _tierColor(streak);
        string memory svg = string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="640" height="640" viewBox="0 0 640 640">',
                '<rect width="640" height="640" fill="#0b0b12"/>',
                '<rect x="24" y="24" width="592" height="592" rx="32" fill="none" stroke="',
                color,
                '" stroke-width="6"/>',
                '<text x="320" y="120" font-family="monospace" font-size="42" fill="',
                color,
                '" text-anchor="middle">AGENT STREAK</text>',
                '<text x="320" y="300" font-family="monospace" font-size="96" fill="#ffffff" text-anchor="middle">',
                streak.toString(),
                '</text>',
                '<text x="320" y="360" font-family="monospace" font-size="28" fill="#9a9ab0" text-anchor="middle">DAY STREAK</text>',
                '<text x="320" y="480" font-family="monospace" font-size="28" fill="#9a9ab0" text-anchor="middle">DAY #',
                day.toString(),
                '</text>',
                '<text x="320" y="540" font-family="monospace" font-size="22" fill="#666678" text-anchor="middle">AGENT ID ONLY - BNB CHAIN</text>',
                "</svg>"
        );
        string memory json = string.concat(
                '{"name":"Agent Streak #',
                tokenId.toString(),
                '",',
                '"description":"Daily check-in collectible for Binance Agent ID holders. Soulbound: one per Agent ID per UTC day, free (gas only). Streak ',
                streak.toString(),
                " on day #",
                day.toString(),
                '.",',
                '"attributes":[{"trait_type":"Day","value":',
                day.toString(),
                '},{"trait_type":"Streak","value":',
                streak.toString(),
                '}],',
                '"image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '"}'
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function _tierColor(uint256 streak) internal pure returns (string memory) {
        if (streak >= 30) return "#c084fc";
        if (streak >= 14) return "#fbbf24";
        if (streak >= 7) return "#38bdf8";
        if (streak >= 3) return "#34d399";
        return "#9a9ab0";
    }
}
