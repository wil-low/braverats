# Braverats!

**Implementation of Seiji Kanai’s filler card game *R*, also known as *BraveRats*!**

A simple two-player simultaneous action selection card game where both players pick cards secretly and reveal them at the same time. Each card has a strength and a special ability that influence the outcome of each round. The first player to win **4 rounds** wins the game.

## 🃏 Game Summary

- **Title:** R (reprinted as *BraveRats*)
- **Designer:** Seiji Kanai
- **Players:** 2
- **Playing Time:** ~5–15 minutes
- **Mechanics:** Simultaneous reveal; card powers override strength.

## 📦 Repository Contents

- `rules.md` — Card effects and game rules.
- Source code — C/C++ implementation(s) of the game logic.
- Platform/console support and build files.

## 🧠 How It Works

Each player has a hand of 8 cards (0–7), each with a unique ability. Players play one card per round simultaneously. The card with the highest effective strength (after special effects) wins the round. The first to reach four round wins claims victory.

## 🪄 Notes

This project is intended as a *reference implementation* of the Braverats game mechanics and can be used for game engines, AI experiments, or as a basis for gameplay simulation.

