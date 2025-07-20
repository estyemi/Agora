## 📘 README: **Agora - A DAO-lite Voting System**

### 📝 Overview

**Agora** is a lightweight, smart contract-based governance system designed for decentralized autonomous organizations (DAOs). It allows users with sufficient voting power to propose, vote, and execute proposals on-chain. This contract offers a minimal yet effective framework for community-driven decision-making with essential features for transparency and control.

---

### ⚙️ Features

* ✅ **Proposal Creation**: Users with enough voting power can create proposals.
* ✅ **On-chain Voting**: Participants vote "yes" or "no" using their allocated voting power.
* ✅ **Proposal Execution**: After the voting period ends, proposals can be executed with outcomes determined by majority votes.
* ✅ **Admin Controls**: The contract owner can set voting power, minimum voting thresholds, and deactivate proposals.
* ✅ **Transparency Tools**: Users can query proposal details, vote records, and status via read-only functions.

---

### 🧱 Contract Structure

* **Data Variables**

  * `proposal-counter`: Tracks the total number of proposals.
  * `min-voting-power`: Minimum tokens required to create or cast votes.
  * `voting-duration`: Duration for which proposals remain active.

* **Maps**

  * `proposals`: Stores metadata and vote counts for each proposal.
  * `votes`: Records individual voter decisions.
  * `user-voting-power`: Maps principals to their voting power.

* **Errors**

  * Custom error codes for various edge cases like double voting, voting before/after period, insufficient power, etc.

---

### 🚀 Usage

#### 1. **Create Proposal**

```clojure
(create-proposal "Upgrade System" "Proposal to upgrade governance model")
```

#### 2. **Vote**

```clojure
(vote u1 true) ;; votes 'yes' on proposal 1
```

#### 3. **Execute Proposal**

```clojure
(execute-proposal u1)
```

#### 4. **Admin Functions**

```clojure
(set-voting-power 'SP... u50)
(set-min-voting-power u10)
(set-voting-duration u720)
(deactivate-proposal u1)
```

---

### 🔐 Access Control

* Only the **contract owner** (creator) can:

  * Set voting power.
  * Change the minimum voting threshold.
  * Adjust voting duration.
  * Deactivate proposals.

---

### 📊 Events

All significant state changes emit logs:

* `proposal-created`
* `vote-cast`
* `proposal-executed`
* `voting-power-updated`
* `proposal-deactivated`

These logs improve traceability and off-chain monitoring.

---

### 🛠️ Deployment Notes

* Ensure the contract owner is set correctly at deployment.
* Set initial user voting power using `set-voting-power`.
* Tune `min-voting-power` and `voting-duration` based on governance needs.


---

### 🧠 Inspiration

**Agora** is inspired by the ancient Greek marketplace of ideas — a digital space for decentralized, fair, and transparent decision-making.
