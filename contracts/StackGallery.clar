;; StacksGallery - NFT Marketplace Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-listing-not-found (err u102))
(define-constant err-price-zero (err u103))
(define-constant err-invalid-token-id (err u104))
(define-constant err-invalid-recipient (err u105))
(define-constant err-invalid-principal (err u106))
(define-constant err-listing-not-active (err u107))

;; Data variables
(define-data-var next-listing-id uint u0)
(define-data-var next-token-id uint u0)
(define-data-var listings-paused bool false)

;; Define the NFT
(define-non-fungible-token nft-token uint)

;; Define listing status enum
(define-data-var listing-status (string-ascii 20) "active")

;; Data structure for listings
(define-map listings
  uint
  {
    token-id: uint,
    price: uint,
    seller: principal,
    status: (string-ascii 20)
  }
)

;; Read-only function to get the next listing ID
(define-read-only (get-next-listing-id)
  (var-get next-listing-id)
)

;; Read-only function to get the next token ID
(define-read-only (get-next-token-id)
  (var-get next-token-id)
)

;; Function to create a new listing
(define-public (create-listing (token-id uint) (price uint))
  (let
    (
      (owner (unwrap! (nft-get-owner? nft-token token-id) err-invalid-token-id))
      (listing-id (var-get next-listing-id))
    )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (> price u0) err-price-zero)
    (asserts! (not (var-get listings-paused)) err-listing-not-active)
    (map-set listings listing-id {token-id: token-id, price: price, seller: tx-sender, status: "active"})
    (var-set next-listing-id (+ listing-id u1))
    (ok listing-id)
  )
)

;; Function to close a listing
(define-public (close-listing (listing-id uint))
  (let
    (
      (listing (unwrap! (map-get? listings listing-id) err-listing-not-found))
      (owner (unwrap! (nft-get-owner? nft-token (get token-id listing)) err-invalid-token-id))
    )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (is-eq (get status listing) "active") err-listing-not-active)
    (ok (map-set listings listing-id 
      (merge listing {status: "closed"})))
  )
)

;; Function to pause all listings (only contract owner)
(define-public (pause-listings)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set listings-paused true)
    (ok true)
  )
)

;; Function to resume all listings (only contract owner)
(define-public (resume-listings)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set listings-paused false)
    (ok true)
  )
)

;; Function to update the price of a listing
(define-public (update-listing-price (listing-id uint) (new-price uint))
  (let
    (
      (listing (unwrap! (map-get? listings listing-id) err-listing-not-found))
      (owner (unwrap! (nft-get-owner? nft-token (get token-id listing)) err-invalid-token-id))
    )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (> new-price u0) err-price-zero)
    (asserts! (is-eq (get status listing) "active") err-listing-not-active)
    (ok (map-set listings listing-id 
      (merge listing {price: new-price})))
  )
)

;; Read-only function to get listing details
(define-read-only (get-listing (listing-id uint))
  (map-get? listings listing-id)
)

;; Function to buy an NFT
(define-public (buy-nft (listing-id uint))
  (let
    (
      (listing (unwrap! (map-get? listings listing-id) err-listing-not-found))
      (buyer tx-sender)
      (seller (get seller listing))
      (price (get price listing))
      (token-id (get token-id listing))
    )
    (asserts! (is-some (nft-get-owner? nft-token token-id)) err-invalid-token-id)
    (asserts! (is-eq (unwrap! (nft-get-owner? nft-token token-id) err-invalid-token-id) seller) err-not-token-owner)
    (asserts! (is-eq (get status listing) "active") err-listing-not-active)
    (try! (stx-transfer? price buyer seller))
    (try! (nft-transfer? nft-token token-id seller buyer))
    (map-set listings listing-id (merge listing {status: "sold"}))
    (ok true)
  )
)
