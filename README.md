# Human-Error

**A fast-paced reaction and memory game built in Godot 4 using GDScript.**

Human-Error is a mobile reflex game based around recognising and reproducing increasingly difficult sequences under time pressure.

The project began as a small prototype and was used to explore reaction timing, input validation, sequence generation, feedback systems and rapid game-development iteration.

---

## Gameplay

The game presents the player with a sequence using a 2×2 grid of tiles.

The player must:

* Watch the sequence.
* Reproduce it correctly.
* Respond as quickly as possible.
* Progress through increasingly difficult rounds.

As the run continues, the sequence becomes harder and the margin for error becomes smaller.

The game also tracks reaction performance and provides feedback depending on the quality of the player's response.

---

## Technical Overview

**Engine:** Godot 4.7
**Language:** GDScript
**Platform:** Mobile / Android
**Version control:** Git / GitHub

The project has been used to develop experience with:

* Sequence generation
* Input validation
* Timing systems
* Millisecond reaction tracking
* Game-state transitions
* UI state management
* Audio feedback
* Difficulty progression
* Error handling
* Rapid prototyping
* Debugging
* Git-based development

---

## Sequence System

The core gameplay revolves around generating and validating tile sequences.

The game handles:

* Random sequence generation
* Sequence playback
* Player input tracking
* Correct input validation
* Incorrect input handling
* Round progression
* Increasing sequence length

The starting sequence is intentionally short, allowing the player to understand the mechanic before complexity increases.

---

## Input Validation

One of the more important parts of the project has been ensuring that player input is only accepted at the correct time.

During development, issues such as extremely fast taps being treated incorrectly required improvements to the input-state logic.

The game now separates states such as:

* Displaying the sequence
* Waiting for player input
* Validating responses
* Completing a round
* Handling mistakes
* Ending a run

This helped prevent player input from being processed during invalid states.

---

## Reaction Timing

Human-Error tracks player reaction performance with high timing precision.

The timing system is used to measure:

* Response speed
* Sequence performance
* Reaction time
* Perfect sequences

This required careful consideration of when timing begins, when input becomes valid and how results are displayed to the player.

---

## Difficulty Progression

The game becomes progressively more challenging as the player advances.

Current progression includes:

* Increasing sequence length
* Faster cognitive load
* More difficult rounds
* Performance-based feedback

Sequence length increases after a set number of completed rounds rather than becoming harder immediately.

This creates a gradual difficulty curve rather than overwhelming the player at the beginning of a run.

---

## Audio Feedback

The project uses separate sound effects for different gameplay events.

Current audio includes:

* Tile press
* Incorrect input
* Perfect sequence
* End of run

The audio system was adjusted during development so that successful sequences and run completion use separate feedback.

This helped make player feedback clearer and more meaningful.

---

## Visual Feedback

The project is intentionally simple mechanically, so visual and audio feedback are important to making interactions feel satisfying.

Current and planned feedback includes:

* Tile press states
* Correct/incorrect feedback
* Perfect sequence effects
* Screen flashes
* Particle effects
* Celebration feedback
* End-of-run presentation

The long-term goal is to make high-performance moments feel significantly more dramatic than normal input.

---

## Game State

The project uses clearly separated gameplay states to control when different systems should run.

This includes logic for:

* Starting the game
* Playing a sequence
* Accepting input
* Completing a round
* Handling incorrect input
* Playing feedback
* Ending the run

This structure became particularly important as more audio, timing and feedback systems were added.

---

## AI-Assisted Development

AI tools have been used during development to help accelerate learning and iteration.

I use AI to:

* Discuss implementation ideas
* Debug unexpected behaviour
* Review game-state logic
* Understand timing issues
* Identify problems with input handling
* Compare alternative solutions
* Refactor scripts
* Explain unfamiliar concepts

AI-generated suggestions are tested manually and adjusted to fit the project.

A recurring part of the process has been identifying cases where a technically valid suggestion still produces incorrect gameplay behaviour and then refining the implementation through testing.

---

## Development Approach

Human-Error has been developed as a rapid prototype.

My workflow has generally been:

1. Define a small gameplay requirement.
2. Implement it quickly.
3. Test the behaviour immediately.
4. Identify edge cases.
5. Fix state or timing problems.
6. Improve player feedback.
7. Commit the working version using Git.

This project has been particularly useful for practising rapid iteration and learning how small timing or state errors can have a large impact on gameplay.

---

## Planned Development

Future development may include:

* Global leaderboards
* Further difficulty balancing
* More detailed performance statistics
* Expanded visual feedback
* Improved perfect-sequence effects
* Additional game modes
* Mobile release preparation

---


## What I Learned

Human-Error has helped me build practical experience with:

* Timing-sensitive code
* Player input
* Game-state management
* Sequence logic
* Debugging edge cases
* UI feedback
* Audio systems
* Iterative prototyping
* Version control

It has also reinforced how important clear state control is in games where player input and timing need to be extremely precise.

---

## Developer

**Ben Carr**

GitHub: [b-cxrr](https://github.com/b-cxrr)

Independent developer building experience in software engineering, Godot, GDScript and AI-assisted development.
