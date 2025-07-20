;; DAO-lite Voting System
;; A simple voting contract for proposals with basic governance features

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-voted (err u102))
(define-constant err-voting-ended (err u103))
(define-constant err-voting-not-ended (err u104))
(define-constant err-insufficient-tokens (err u105))
(define-constant err-proposal-not-active (err u106))

;; Data Variables
(define-data-var proposal-counter uint u0)
(define-data-var min-voting-power uint u1) ;; Minimum tokens needed to vote
(define-data-var voting-duration uint u1440) ;; Default 1440 blocks (~10 days)

;; Data Maps
(define-map proposals
  uint
  {
    title: (string-utf8 256),
    description: (string-utf8 1024),
    proposer: principal,
    start-block: uint,
    end-block: uint,
    yes-votes: uint,
    no-votes: uint,
    total-voters: uint,
    executed: bool,
    active: bool
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool, voting-power: uint }
)

(define-map user-voting-power
  principal
  uint
)

;; Read-only functions
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

(define-read-only (get-voting-power (user principal))
  (default-to u0 (map-get? user-voting-power user))
)

(define-read-only (get-proposal-count)
  (var-get proposal-counter)
)

(define-read-only (is-voting-active (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal (and 
      (get active proposal)
      (>= block-height (get start-block proposal))
      (<= block-height (get end-block proposal))
    )
    false
  )
)

(define-read-only (get-proposal-status (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal (some {
      proposal-id: proposal-id,
      title: (get title proposal),
      yes-votes: (get yes-votes proposal),
      no-votes: (get no-votes proposal),
      total-voters: (get total-voters proposal),
      is-active: (is-voting-active proposal-id),
      executed: (get executed proposal)
    })
    none
  )
)

;; Public functions
(define-public (create-proposal (title (string-utf8 256)) (description (string-utf8 1024)))
  (let
    (
      (proposal-id (+ (var-get proposal-counter) u1))
      (start-block block-height)
      (end-block (+ block-height (var-get voting-duration)))
    )
    ;; Check if user has minimum voting power to create proposals
    (asserts! (>= (get-voting-power tx-sender) (var-get min-voting-power)) err-insufficient-tokens)
    
    ;; Create the proposal
    (map-set proposals proposal-id {
      title: title,
      description: description,
      proposer: tx-sender,
      start-block: start-block,
      end-block: end-block,
      yes-votes: u0,
      no-votes: u0,
      total-voters: u0,
      executed: false,
      active: true
    })
    
    ;; Update proposal counter
    (var-set proposal-counter proposal-id)
    
    (print { event: "proposal-created", proposal-id: proposal-id, proposer: tx-sender })
    (ok proposal-id)
  )
)

(define-public (vote (proposal-id uint) (support bool))
  (let
    (
      (voter tx-sender)
      (voting-power (get-voting-power voter))
      (proposal (unwrap! (map-get? proposals proposal-id) err-not-found))
    )
    ;; Validation checks
    (asserts! (is-voting-active proposal-id) err-proposal-not-active)
    (asserts! (>= voting-power (var-get min-voting-power)) err-insufficient-tokens)
    (asserts! (is-none (map-get? votes { proposal-id: proposal-id, voter: voter })) err-already-voted)
    
    ;; Record the vote
    (map-set votes 
      { proposal-id: proposal-id, voter: voter }
      { vote: support, voting-power: voting-power }
    )
    
    ;; Update proposal vote counts
    (map-set proposals proposal-id
      (merge proposal {
        yes-votes: (if support 
          (+ (get yes-votes proposal) voting-power)
          (get yes-votes proposal)
        ),
        no-votes: (if support
          (get no-votes proposal)
          (+ (get no-votes proposal) voting-power)
        ),
        total-voters: (+ (get total-voters proposal) u1)
      })
    )
    
    (print { event: "vote-cast", proposal-id: proposal-id, voter: voter, support: support, voting-power: voting-power })
    (ok true)
  )
)

(define-public (execute-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) err-not-found))
    )
    ;; Check if voting has ended
    (asserts! (> block-height (get end-block proposal)) err-voting-not-ended)
    (asserts! (not (get executed proposal)) err-proposal-not-active)
    
    ;; Mark as executed (regardless of outcome)
    (map-set proposals proposal-id
      (merge proposal { executed: true })
    )
    
    (let
      (
        (yes-votes (get yes-votes proposal))
        (no-votes (get no-votes proposal))
        (passed (> yes-votes no-votes))
      )
      (print { 
        event: "proposal-executed", 
        proposal-id: proposal-id, 
        passed: passed,
        yes-votes: yes-votes,
        no-votes: no-votes
      })
      (ok passed)
    )
  )
)

;; Admin functions
(define-public (set-voting-power (user principal) (power uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set user-voting-power user power)
    (print { event: "voting-power-updated", user: user, power: power })
    (ok true)
  )
)

(define-public (set-min-voting-power (new-min uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set min-voting-power new-min)
    (ok true)
  )
)

(define-public (set-voting-duration (new-duration uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set voting-duration new-duration)
    (ok true)
  )
)

(define-public (deactivate-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set proposals proposal-id
      (merge proposal { active: false })
    )
    (print { event: "proposal-deactivated", proposal-id: proposal-id })
    (ok true)
  )
)

;; Initialize contract with owner voting power
(map-set user-voting-power contract-owner u100)