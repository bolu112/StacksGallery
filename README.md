
# StacksGallery - NFT Marketplace on Stacks Blockchain

This Clarity smart contract implements a basic **NFT Marketplace** on the [Stacks Blockchain](https://www.stacks.co/), allowing users to mint NFTs, list them for sale, update or cancel listings, and purchase NFTs with STX tokens. It includes administrative controls for managing marketplace activity and keeping track of active listings.

---

## 📜 Contract Features

- **NFT Minting:** Only the contract owner can mint new NFTs.
- **Listings:** Users can list their NFTs for sale with a specific price.
- **Buying:** Anyone can buy a listed NFT by paying the listed price.
- **Listing Management:** Sellers can update or close their listings.
- **Marketplace Controls:** The contract owner can pause or resume all listings.
- **Active Listings Tracking:** Active listings per seller are tracked in real time.

---

## 🛠️ Constants & Errors

```clarity
contract-owner            ;; The address that deployed the contract
err-owner-only            ;; u100 - Only the contract owner can call
err-not-token-owner       ;; u101 - Caller is not the NFT owner
err-listing-not-found     ;; u102 - No such listing exists
err-price-zero            ;; u103 - Listing price cannot be zero
err-invalid-token-id      ;; u104 - Invalid or nonexistent token ID
err-invalid-recipient     ;; u105 - Invalid principal passed to mint
err-invalid-principal     ;; u106 - General principal validation
err-listing-not-active    ;; u107 - Listing is not active
```

---

## 🔐 Roles

- **Contract Owner:** The deploying address. Can mint NFTs and pause/resume listings.
- **Users:** Can list, update, close, and buy NFTs they own.

---

## 📦 Storage Variables

- `next-token-id`: Tracks the next token ID to mint.
- `next-listing-id`: Tracks the next listing ID.
- `listings`: Map of listing ID to listing data.
- `listings-paused`: Boolean to control the ability to create new listings.
- `active-listings-count`: Map of principal → active listing count.
- `nft-token`: The NFT defined using `define-non-fungible-token`.

---

## 📇 Listing Structure

```clarity
{
  token-id: uint,
  price: uint,
  seller: principal,
  status: (string-ascii 20) ;; "active", "closed", "sold"
}
```

---

## 📚 Function Reference

### 🔹 Minting NFTs

```clarity
(mint-nft (recipient principal)) → (ok token-id)
```
Only the contract owner can mint NFTs to a valid recipient.

---

### 🔹 Listing NFTs

```clarity
(create-listing (token-id uint) (price uint)) → (ok listing-id)
```
Creates a listing for a token you own. Must be active and have a non-zero price.

---

### 🔹 Buying NFTs

```clarity
(buy-nft (listing-id uint)) → (ok true)
```
Transfers the NFT to the buyer and sends the STX to the seller if the listing is active and valid.

---

### 🔹 Closing Listings

```clarity
(close-listing (listing-id uint)) → (ok ...)
```
Marks a listing as "closed". Only the NFT owner can close their listing.

---

### 🔹 Updating Listing Price

```clarity
(update-listing-price (listing-id uint) (new-price uint)) → (ok ...)
```
Allows the seller to change the price of an active listing.

---

### 🔹 Marketplace Controls (Owner Only)

```clarity
(pause-listings) → (ok true)
(resume-listings) → (ok true)
```
Enables or disables the ability to create new listings.

---

### 🔹 Read-Only Utilities

```clarity
(get-next-token-id) → uint
(get-next-listing-id) → uint
(get-listing (listing-id uint)) → (optional listing-data)
(get-nft-owner (token-id uint)) → (optional principal)
(get-total-listings) → uint
(get-active-listings-count (seller principal)) → uint
```

---

## 🔄 Active Listings Counter

To improve performance and enable better tracking, the contract maintains a per-user count of active listings via:

- `increment-active-listings`
- `decrement-active-listings`

These are private helper functions called internally when creating, closing, or completing a sale.

---

## ⚠️ Notes & Limitations

- **Active Listings Count:** This is tracked per user but may desync in edge cases (e.g., failed internal state updates).
- **Listing Enumeration:** There's no current function to enumerate all listings beyond a fixed count.
- **No Royalties or Fees:** The marketplace does not currently support royalties or protocol fees.
- **Single NFT Type:** Only one `nft-token` type is supported in this contract.

---

## 🧪 Testing

Make sure to thoroughly test each function in a development environment like [Clarinet](https://docs.stacks.co/write-smart-contracts/clarinet/overview).

Sample test cases should include:

- Minting and verifying ownership.
- Listing NFTs.
- Purchasing NFTs.
- Attempting to list a token not owned.
- Owner-only operations (pause/resume/mint).

---
