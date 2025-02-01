;; ZenithNode Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant min-stake u100000)
(define-constant err-unauthorized (err u100))
(define-constant err-insufficient-stake (err u101))
(define-constant err-node-exists (err u102))
(define-constant err-node-not-found (err u103))

;; Data vars
(define-data-var total-nodes uint u0)
(define-data-var total-stake uint u0)

;; Data maps
(define-map nodes 
  principal 
  {
    stake: uint,
    status: (string-ascii 20),
    uptime: uint,
    rewards: uint,
    registration-height: uint
  }
)

;; Node registration
(define-public (register-node (stake uint))
  (let ((node-data (map-get? nodes tx-sender)))
    (if (is-some node-data)
      err-node-exists
      (if (>= stake min-stake)
        (begin
          (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
          (map-set nodes tx-sender {
            stake: stake,
            status: "active",
            uptime: u100,
            rewards: u0,
            registration-height: block-height
          })
          (var-set total-nodes (+ (var-get total-nodes) u1))
          (var-set total-stake (+ (var-get total-stake) stake))
          (ok true))
        err-insufficient-stake))))

;; Update node status
(define-public (update-status (node principal) (new-status (string-ascii 20)))
  (if (is-eq tx-sender contract-owner)
    (match (map-get? nodes node)
      node-data (begin
        (map-set nodes node (merge node-data {status: new-status}))
        (ok true))
      err-node-not-found)
    err-unauthorized))

;; Claim rewards
(define-public (claim-rewards)
  (match (map-get? nodes tx-sender)
    node-data (begin 
      (map-set nodes tx-sender (merge node-data {rewards: u0}))
      (ok true))
    err-node-not-found))

;; Read only functions
(define-read-only (get-node-info (node principal))
  (ok (map-get? nodes node)))

(define-read-only (get-total-nodes)
  (ok (var-get total-nodes)))

(define-read-only (get-total-stake)
  (ok (var-get total-stake)))
