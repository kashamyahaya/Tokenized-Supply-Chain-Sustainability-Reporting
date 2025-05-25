;; Entity Verification Contract
;; Validates and manages reporting organizations

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ENTITY_EXISTS (err u101))
(define-constant ERR_ENTITY_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Data Variables
(define-data-var next-entity-id uint u1)

;; Data Maps
(define-map entities
  { entity-id: uint }
  {
    name: (string-ascii 100),
    address: principal,
    industry: (string-ascii 50),
    registration-date: uint,
    status: (string-ascii 20),
    verifier: principal
  }
)

(define-map entity-by-address
  { address: principal }
  { entity-id: uint }
)

;; Public Functions

;; Register a new entity
(define-public (register-entity (name (string-ascii 100)) (industry (string-ascii 50)))
  (let ((entity-id (var-get next-entity-id))
        (caller tx-sender))
    (asserts! (is-none (map-get? entity-by-address { address: caller })) ERR_ENTITY_EXISTS)
    (map-set entities
      { entity-id: entity-id }
      {
        name: name,
        address: caller,
        industry: industry,
        registration-date: block-height,
        status: "pending",
        verifier: CONTRACT_OWNER
      }
    )
    (map-set entity-by-address { address: caller } { entity-id: entity-id })
    (var-set next-entity-id (+ entity-id u1))
    (ok entity-id)
  )
)

;; Verify an entity (only contract owner)
(define-public (verify-entity (entity-id uint))
  (let ((entity (unwrap! (map-get? entities { entity-id: entity-id }) ERR_ENTITY_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set entities
      { entity-id: entity-id }
      (merge entity { status: "verified" })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get entity by ID
(define-read-only (get-entity (entity-id uint))
  (map-get? entities { entity-id: entity-id })
)

;; Get entity ID by address
(define-read-only (get-entity-id-by-address (address principal))
  (map-get? entity-by-address { address: address })
)

;; Check if entity is verified
(define-read-only (is-entity-verified (entity-id uint))
  (match (map-get? entities { entity-id: entity-id })
    entity (is-eq (get status entity) "verified")
    false
  )
)
