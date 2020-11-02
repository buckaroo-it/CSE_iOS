# Client Side Encryption SDK for iOS
> This SDK is used to encrypt card data on the client side. In this case on the iOS device itself. The crypted data that is created by CSE can be transferred to the Buckaroo API through you own server.

## Requirements
The Buckaroo CSE SDK for iOS is written in Swift and is compatible with iOS devices with version 10+. No other dependencies are required.

## Getting Started
See below an example of how to use this SDK to encrypt some dummy card credentials.
```swift
do {
	let encryptCardDataResult = try CSE.encrypt(cardNumber: "5386860000000000", year: "2020", month: "12", cvc: "123", cardholder: "A DE GROOT")
	print("encryptedCardData: \(encryptCardDataResult)")
} catch {
	print("encryptError: \(error)")
}
```
