# Agent Streak

Daily check-in dApp for **Binance Agent ID** holders on BNB Chain — built for the
[Binance Agent ID Hackathon](https://www.binance.com/en/support/announcement/detail/95f5dbe0ea674a48a739b59e046648bf)
(submission period 18 Nov – 9 Dec 2026).

Every Agent ID holder checks in once per UTC day and mints a **free soulbound
ERC-721 collectible** that records their on-chain streak. No owner, no admin
functions, no fees — value 0, gas only.

## Live

- **Website:** https://muse.ai/s/agent-streak-go6xzxvxcxyz1fxm/sOwTk03t2xgU3ymVRAkuK88ELdk5WL6wUZQbKdS343o
- **Contract (BNB Chain):** [`0xC416B0A7471dCd9c8b285C1A6C8Aed98368a0D81`](https://bscscan.com/address/0xC416B0A7471dCd9c8b285C1A6C8Aed98368a0D81)
- **Source verified:** [BscScan](https://bscscan.com/address/0xC416B0A7471dCd9c8b285C1A6C8Aed98368a0D81) ·
  Sourcify exact match
- **Demo video:** [`demo/agent-streak-demo.mp4`](demo/agent-streak-demo.mp4)

## How it works

`checkIn()` in [`src/AgentStreak.sol`](src/AgentStreak.sol) gates on the Agent ID
registry (`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`): it calls
`balanceOf(msg.sender)` and reverts `NotAgentIdHolder()` for non-holders. A
second check-in on the same UTC day reverts `AlreadyCheckedInToday()`.

Each check-in:

- increments the holder's streak (resets to 1 if the previous day was missed),
- mints one soulbound ERC-721 (transfers always revert) with fully on-chain
  SVG metadata — the token shows the streak number, the day, and a tier color
  (3 / 7 / 14 / 30 days),
- emits `CheckIn(user, day, streak, tokenId)`.

Views: `streakOf`, `lastCheckInDay`, `totalCheckInsOf`, `hasCheckedInToday`,
`totalCheckIns`.

## Build & test

Requires [Foundry](https://book.getfoundry.sh/).

```shell
forge install   # OpenZeppelin contracts
forge build
forge test      # 7/7 tests: gating, once-per-day, streak increment/reset, soulbound, tokenURI
```

## Deploy

```shell
cast send --create $(cat deploy-init.txt) --rpc-url https://bsc-dataseed.binance.org/ --private-key <deployer-key>
```

Deployed 2026-11-18, tx
[`0x12508fdeb7bf09cd93a46fe9e7efc3356b32ce7043bec07bf84cb920fefda508`](https://bscscan.com/tx/0x12508fdeb7bf09cd93a46fe9e7efc3356b32ce7043bec07bf84cb920fefda508),
block 134319812.
