// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AgentStreak} from "../src/AgentStreak.sol";

contract MockRegistry {
    mapping(address => uint256) public balanceOf;

    function set(address user, uint256 n) external {
        balanceOf[user] = n;
    }
}

contract AgentStreakTest is Test {
    AgentStreak public streak;
    MockRegistry public registry;

    address holder = address(0xA11CE);
    address stranger = address(0xB0B);

    uint256 constant DAY0 = 1794819600; // 2026-11-16 09:00 UTC, a UTC-day boundary

    function setUp() public {
        registry = new MockRegistry();
        streak = new AgentStreak(address(registry));
        registry.set(holder, 1);
        vm.warp(DAY0 + 3600); // day 0, one hour in
    }

    function testNonHolderReverts() public {
        vm.prank(stranger);
        vm.expectRevert(AgentStreak.NotAgentIdHolder.selector);
        streak.checkIn();
    }

    function testCheckInMintsStreakOne() public {
        vm.prank(holder);
        streak.checkIn();
        assertEq(streak.balanceOf(holder), 1);
        assertEq(streak.ownerOf(1), holder);
        assertEq(streak.streakOf(holder), 1);
        assertEq(streak.tokenStreak(1), 1);
        assertEq(streak.totalCheckIns(), 1);
        assertTrue(streak.hasCheckedInToday(holder));
    }

    function testSecondCheckInSameDayReverts() public {
        vm.prank(holder);
        streak.checkIn();
        vm.prank(holder);
        vm.expectRevert(AgentStreak.AlreadyCheckedInToday.selector);
        streak.checkIn();
    }

    function testNextDayStreakTwo() public {
        vm.prank(holder);
        streak.checkIn();
        vm.warp(DAY0 + 1 days + 3600);
        vm.prank(holder);
        streak.checkIn();
        assertEq(streak.streakOf(holder), 2);
        assertEq(streak.tokenStreak(2), 2);
        assertEq(streak.totalCheckInsOf(holder), 2);
    }

    function testMissedDayResetsStreak() public {
        vm.prank(holder);
        streak.checkIn();
        vm.warp(DAY0 + 3 days + 3600); // skipped a day
        vm.prank(holder);
        streak.checkIn();
        assertEq(streak.streakOf(holder), 1);
    }

    function testSoulboundTransferReverts() public {
        vm.prank(holder);
        streak.checkIn();
        vm.prank(holder);
        vm.expectRevert("AgentStreak: soulbound, transfers disabled");
        streak.transferFrom(holder, stranger, 1);
    }

    function testTokenUriPrefix() public {
        vm.prank(holder);
        streak.checkIn();
        string memory uri = streak.tokenURI(1);
        string memory prefix = "data:application/json;base64,";
        bytes memory uriBytes = bytes(uri);
        bytes memory prefixBytes = bytes(prefix);
        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(uriBytes[i], prefixBytes[i]);
        }
        assertGt(uriBytes.length, prefixBytes.length + 100);
    }
}
