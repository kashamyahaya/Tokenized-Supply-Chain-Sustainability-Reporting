;; Sustainability Metrics Contract
;; Defines and manages environmental measures

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_METRIC_EXISTS (err u201))
(define-constant ERR_METRIC_NOT_FOUND (err u202))

;; Data Variables
(define-data-var next-metric-id uint u1)

;; Data Maps
(define-map metrics
  { metric-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    unit: (string-ascii 20),
    category: (string-ascii 50),
    created-by: principal,
    created-at: uint,
    is-active: bool
  }
)

(define-map metric-by-name
  { name: (string-ascii 100) }
  { metric-id: uint }
)

;; Public Functions

;; Create a new sustainability metric
(define-public (create-metric
  (name (string-ascii 100))
  (description (string-ascii 500))
  (unit (string-ascii 20))
  (category (string-ascii 50)))
  (let ((metric-id (var-get next-metric-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? metric-by-name { name: name })) ERR_METRIC_EXISTS)
    (map-set metrics
      { metric-id: metric-id }
      {
        name: name,
        description: description,
        unit: unit,
        category: category,
        created-by: tx-sender,
        created-at: block-height,
        is-active: true
      }
    )
    (map-set metric-by-name { name: name } { metric-id: metric-id })
    (var-set next-metric-id (+ metric-id u1))
    (ok metric-id)
  )
)

;; Deactivate a metric
(define-public (deactivate-metric (metric-id uint))
  (let ((metric (unwrap! (map-get? metrics { metric-id: metric-id }) ERR_METRIC_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set metrics
      { metric-id: metric-id }
      (merge metric { is-active: false })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get metric by ID
(define-read-only (get-metric (metric-id uint))
  (map-get? metrics { metric-id: metric-id })
)

;; Get metric ID by name
(define-read-only (get-metric-id-by-name (name (string-ascii 100)))
  (map-get? metric-by-name { name: name })
)

;; Check if metric is active
(define-read-only (is-metric-active (metric-id uint))
  (match (map-get? metrics { metric-id: metric-id })
    metric (get is-active metric)
    false
  )
)

;; Get next metric ID
(define-read-only (get-next-metric-id)
  (var-get next-metric-id)
)
