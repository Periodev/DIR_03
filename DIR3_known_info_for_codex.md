# DIR3.0 Known Information for Codex

Last updated: 2026-06-23
Project: DIR, not DIV
Purpose: implementation/design handoff for Codex. This document records known decisions, unresolved questions, and puzzle requirements. It should not invent new mechanics unless explicitly marked as proposal.

---

## 1. High-level identity

DIR3.0 is a rewrite of the DIR concept around **direction/momentum as a first-class resource**.

Earlier versions:

- **DIR1.0**: store/release only. U/D/L/R were fixed. Player displacement was the main observable effect.
- **DIR2.0**: added composition and turning. Produced many multi-solution movement-efficiency puzzles, but the design drifted toward efficient movement rather than a distinct direction-resource puzzle language.
- **DIR3.0**: direction is treated as something that can be generated, stored, transferred, and released. The goal is to produce puzzles not expressible as DIV-style split/merge or DIR2.0 movement optimization.

Core framing:

- Player does not merely move.
- Player manipulates future motion commands.
- A direction can exist before it is applied.
- A block or slot may hold a direction as potential.
- The puzzle is about when and where stored direction becomes motion.

---

## 2. Core loop

DIR3.0 currently uses a three-stage loop:

1. **Generate**
   - A push action creates direction/momentum.
   - The direction itself should not be freely editable after creation.
   - The first-level operation is still **push**.

2. **Store**
   - Generated direction can enter a carrier or state.
   - Candidate storage forms:
     - player slot/state slot
     - empty block / direction block
     - ground flag or tile state
     - temporary environmental residue

3. **Release / Trigger**
   - Stored direction later becomes displacement or push force.
   - Trigger timing is the central design problem.
   - Release may be manual, collision-based, position-based, or bound to a slot.

Terminology approximation:

- Stored direction = **potential**.
- Release path/object = **conductor**.
- Trigger = converting potential into actual movement.

---

## 3. Operation hierarchy

### First-level operation

- **Push** is the first-level operation.
- The player pushes objects or performs an empty push to produce direction/momentum.
- DIR3.0 should avoid starting from many independent verbs.

### Candidate second-level operation

- An **interact key** is being considered.
- It may handle adjacent release or transfer.
- This is inspired partly by DIV having separate object/world interaction, but DIR3.0 must not become DIV.

Current likely use of interact:

- Interact with an adjacent object to transfer or release stored direction.
- Possibly bind a stored direction after transfer.
- Avoid pure remote trigger unless there is no alternative.

---

## 4. Storage models under consideration

### 4.1 Player slot

A player slot holds one direction/momentum unit.

Possible traits:

- finite capacity
- direction cannot be edited directly
- can be released later
- may bind to an object or slot after transfer

Open questions:

- How many slots are allowed?
- Does slot capacity scale across zones?
- Does slot release require adjacency?
- Can a slot be bound to a non-adjacent object?

### 4.2 Direction block / empty block carrier

A block can hold a direction.

Possible traits:

- direction is stored inside the object
- pushing the object may move it without immediately releasing stored direction
- a later trigger releases the stored direction

This enables spring-like or delayed-force puzzles.

### 4.3 Ground or tile state

A tile can store or provide direction.

Possible traits:

- stepping on a tile may absorb, assign, or release a direction
- useful for simplifying input, but may become too automatic

Risk:

- If every transfer is automatic, the game may become closer to Maxwell-style state automation and less like DIR's intended push-first puzzle.

### 4.4 Environmental residue

A direction may temporarily remain in the world after an action.

Status:

- Mentioned as a possible source/state.
- Not yet selected as a core rule.

---

## 5. Release / trigger models under consideration

### 5.1 Countdown release

Stored direction releases after a number of steps.

Status:

- Candidate only.
- May simplify timing, but risks making puzzles about counting rather than spatial reasoning.

### 5.2 Collision release

Stored direction releases when object/player collision conditions are met.

Possible condition:

- player is adjacent
- player presses direction or interact
- object has stored momentum

Status:

- Attractive because it preserves locality.
- May replace remote trigger in some cases.

### 5.3 Position/tile trigger

Stored direction releases when the carrier reaches a tile.

Status:

- Candidate.
- Useful for level-authored timing.
- Risk: too much logic moves into map fixtures.

### 5.4 Push-trigger release

Stored direction releases only after the carrier is pushed or moved first.

Known use:

- Pre-store a direction.
- Push the carrier in another direction.
- Release stored direction afterward.
- This can produce spring, orthogonal rotation, and indirect motion effects.

### 5.5 Slot-bound remote release

A stored direction can be bound to a slot/object and released later, possibly from non-adjacent position.

Status:

- This solves some known puzzle needs.
- It is also dangerously close to remote triggering, which the design currently wants to avoid or strictly limit.

Key unresolved conflict:

- Some intended levels require non-adjacent timing.
- But unrestricted remote trigger weakens the locality rule.

---

## 6. Known design conflict: remote timing vs locality

A central DIR3.0 problem:

- Some puzzles require the player to trigger motion when they are no longer adjacent to the object.
- But allowing arbitrary remote trigger may flatten the puzzle into command storage and delayed execution.

Current framing:

- The issue is not simply distance.
- The issue is **who decides the timing**.
- If the level requires a non-adjacent timing moment, then either:
  - the system must allow a constrained remote trigger, or
  - the level must provide a local/physical trigger at the target timing.

Current preference:

- Avoid unrestricted remote trigger.
- Prefer adjacency, collision, path, tile, or bound-slot constraints.
- Allow remote-like behavior only when it is structured enough to remain a puzzle object, not a general command button.

---

## 7. Known puzzle sketches

### 7.1 Fold-back block / crossroad problem

Scenario:

- Crossroad-like space.
- A central block blocks the route.
- Player wants to push it from below to the right-side target.

Observed requirement:

- Store a downward direction.
- Transfer or convert it so the block later moves upward by one unit.
- Player then walks to the left side.
- Player must trigger the block at a timing/location where direct adjacency may be impossible.
- Then push the block right.

Design issue:

- Without non-adjacent timing, the puzzle may be impossible.
- This is the main example forcing the remote-trigger discussion.

### 7.2 Spring-like mechanism

Scenario:

- Pre-store a direction in a block.
- Push the block in the opposite or orthogonal direction.
- Later release the stored direction.

Effect:

- Creates a spring or recoil-like behavior.
- Can synthesize indirect motion from simple push + delayed release.

Importance:

- This may be the first clear DIR3.0-native pattern.
- It was recognized as a major step after months of DIR iteration.

### 7.3 Orthogonal rotation

Scenario:

- A stored direction is released after the object has been moved along another axis.

Effect:

- Produces a turn-like or rotation-like spatial result.
- More useful to DIR3.0 than pure dash/efficiency movement.

### 7.4 Dash

Scenario:

- Stored direction releases as straight extra movement.

Status:

- Known derived effect.
- Currently may not have strong use cases.
- Not a priority unless levels demand it.

### 7.5 Self-pull / reverse momentum

Scenario:

- Direction can be used to move/pull the player or object relationship rather than simply push away.

Status:

- Candidate derived pattern.
- At least four basic rules may be composable if self-pull exists.

---

## 8. Relationship to DIV

Important: do not confuse DIR with DIV.

DIV:

- centered on split/merge
- two interactions were considered: object interaction and world interaction
- deals with overlapping or combining solution states

DIR3.0:

- centered on direction as stored resource
- push remains the first-level operation
- interact, if added, should support direction transfer/release rather than become DIV-like state manipulation

Implementation naming should avoid DIV assumptions.

---

## 9. Relationship to reference games

References used for comparison, not direct targets:

- **Patrick's Parabox**: direction/spatial recursion reference, but DIR should not become box-recursion.
- **ChuChu Rocket!**: direction arrows as future path commands.
- **SpaceChem / Zachtronics**: path and timing programming, but DIR should stay tactile and push-based.
- **Maxwell's Demon Puzzle**: state stored in blocks. Its simplification comes from ignoring heat transfer and letting state transitions become automatic. DIR3.0 does not want full automation.
- **Outpour**: physically complex puzzle reference. DIR3.0 should avoid depending on opaque physical complexity.

---

## 10. Implementation assumptions for Codex

These are safe implementation-facing assumptions unless contradicted later:

- Grid-based movement.
- Direction enum: Up, Down, Left, Right.
- Turn-based or step-based resolution is likely.
- Push is the primary action.
- Stored direction should be represented explicitly in state, not inferred from animation.
- Direction storage and release should be deterministic.
- Rules should be testable with small board fixtures.
- Avoid hidden physics unless explicitly added.

Suggested model objects:

- `Direction`
- `Momentum` or `StoredDirection`
- `Carrier` / `DirectionCarrier`
- `PlayerSlot`
- `TriggerRule`
- `ReleaseEvent`
- `GridObject`
- `TileTrigger`

Naming caution:

- Avoid `DIV` names.
- Avoid overly abstract names that hide whether something is a stored direction, a trigger, or a movement result.

---

## 11. Minimum prototype target

A useful prototype should prove these cases first:

1. Player can push to generate a stored direction.
2. A block or player slot can hold a direction.
3. Stored direction can be transferred or bound under a clear rule.
4. Stored direction can later release into movement.
5. Release timing can be tested under at least one local rule.
6. The spring-like pattern works.
7. The crossroad/fold-back problem can be tested, even if the final remote-trigger policy is unresolved.

---

## 12. Open questions

### Rule questions

- Is interact key allowed as a permanent second verb?
- Does interact mean transfer, release, bind, or all of them?
- Is release automatic or manual?
- Is trigger timing decided at setting time or launch time?
- Can a stored direction be remotely released?
- If remote release exists, what constrains it?
- Can an object hold multiple directions?
- If multiple directions enter the same carrier, do they stack, queue, overwrite, or reject?
- Are diagonal or composite movements forbidden, or only derived from sequential cardinal releases?

### Level design questions

- Can every intended fold-back puzzle be solved with locality-preserving triggers?
- Are tile triggers acceptable, or do they make the level too authored?
- Does dash produce meaningful puzzles or only movement efficiency?
- How many early levels are needed before introducing transfer/release distinction?

### UX questions

- How should stored direction be displayed?
- Should direction be visible inside blocks?
- Should player slot UI show capacity and direction?
- How much preview should release actions provide?

---

## 13. Current design stance

- Keep DIR3.0 minimal.
- Push remains the root action.
- Direction storage is the core novelty.
- Do not add remote trigger casually.
- Do not add automation just to solve one level.
- Prefer rules that produce spring/orthogonal-turn patterns naturally.
- Treat the fold-back block as the stress test for the release model.

