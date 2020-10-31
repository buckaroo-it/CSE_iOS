import Foundation

public enum CSE {
    private static func lengthField(of valueField: [UInt8]) -> [UInt8] {
        var count = valueField.count

        if count < 128 {
            return [ UInt8(count) ]
        }
        
        // The number of bytes needed to encode count.
        let lengthBytesCount = Int((log2(Double(count)) / 8) + 1)

        // The first byte in the length field encoding the number of remaining bytes.
        let firstLengthFieldByte = UInt8(128 + lengthBytesCount)

        var lengthField: [UInt8] = []
        for _ in 0..<lengthBytesCount {
            // Take the last 8 bits of count.
            let lengthByte = UInt8(count & 0xff)
            // Add them to the length field.
            lengthField.insert(lengthByte, at: 0)
            // Delete the last 8 bits of count.
            count = count >> 8
        }

        // Include the first byte.
        lengthField.insert(firstLengthFieldByte, at: 0)

        return lengthField
    }
    
    private static func GetKey() -> SecKey {
        let modulus: [UInt8] = Array(Data(base64Encoded: "AODXS2u1iKvsoHE6OLRhbvHnO6kcLWdYyxIyp7V37OeoGlrWmEsXPnq+5Yxttq27+NU+a2mH3c7z6ld2HExQji6XSSCZM076K2PiA0dPZDerhyhrrUo3ZA6WKyhR3lP8dFuz9BlFtknNeAexvy/AtnjEqpAwDLQDcrzgh3ZP9nIWDoGKiLmXyJ02jRMx22G+ovg+bCnrtQ9eRtrhBWPoJLi5rQ6t8T1MyvxvoWhuCrCC+SSm7fpFd/w4m7tzlKYjAzdWKaHKmlEebKBZioiYtTx7YEGdGsnV8b3hyEYbRPuRYC+8N9O4DqmzCeKt31wwGUMygcJTWJ8IAGhVtT0s5Pc=")!)
        let exponent: [UInt8] = Array(Data(base64Encoded: "AQAB")!)
        
        var modulusEncoded: [UInt8] = []
        modulusEncoded.append(0x02)
        modulusEncoded.append(contentsOf: lengthField(of: modulus))
        modulusEncoded.append(contentsOf: modulus)

        var exponentEncoded: [UInt8] = []
        exponentEncoded.append(0x02)
        exponentEncoded.append(contentsOf: lengthField(of: exponent))
        exponentEncoded.append(contentsOf: exponent)
        
        var sequenceEncoded: [UInt8] = []
        sequenceEncoded.append(0x30)
        sequenceEncoded.append(contentsOf: lengthField(of: (modulusEncoded + exponentEncoded)))
        sequenceEncoded.append(contentsOf: (modulusEncoded + exponentEncoded))
        
        let keyData = Data(sequenceEncoded)

        // RSA key size is the number of bits of the modulus.
        let keySize = (modulus.count * 8)

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: keySize
        ]

        let publicKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, nil)
        return publicKey!
    }
    
    /**
     Encrypts the data using RSA public key encryption.
     :returns: A base64 encoded value that can be used to initiate a transaction using the Buckaroo Payment Gateway
     */
    public static func encryptCardData(cardNumber: String, year: String, month: String, cvc: String, cardholder: String) throws -> String {
        let key = GetKey()
        let data = "\(cardNumber),\(year),\(month),\(cvc),\(cardholder)".data(using: String.Encoding.utf8)!
        var error: Unmanaged<CFError>?
        let encrypted = SecKeyCreateEncryptedData(key, SecKeyAlgorithm.rsaEncryptionOAEPSHA1, data as CFData, &error )!
        
        if (error != nil) {
            throw CSEError("Encrypting card data failed.")
        }
        
        return "001" + (encrypted as Data).base64EncodedString()
    }

    /**
     Checks if a valid cvc is entered. The following checks are performed:
     1. Digits only
     2. 3 digits for Mastercard & Visa
     3. 4 digits for Amex
     4. No cvc for Bancontact or Maestro
     5. 0, 3 or 4 digits for Unknown
    */
    public static func validateCvc(cvcString: String, cardBrand: CardBrand) -> Bool {
        // Determine if the cvc has the correct length.
        if (cardBrand == CardBrand.Unknown) {
            // We do not know the card service, so accept cvc length of 0, 3, or 4.
            if (cvcString.count == 0) {
                return true;
            }
            if (cvcString.count != 3 && cvcString.count != 4) {
                return false;
            }
        }
        else {
            switch (cardBrand) {
            case CardBrand.Bancontact, CardBrand.Maestro:
                    // These card services does not use a cvc so no cvc should be set.
                    return cvcString.count == 0;
            case CardBrand.Amex:
                    // American Express uses a cvc with 4 digits.
                    if (cvcString.count != 4) {
                        return false;
                    }
                    break;
                default:
                    // All other card services uses cvc with 3 digits.
                    if (cvcString.count != 3) {
                        return false;
                    }
                    break;
            }
        }
        // Accept only digits
        if (cvcString.range(of: #"[^0-9]+"#,
        options: .regularExpression) != nil) {
            return false;
        }
        return true;
    };

    /**
     Checks if a valid year digit is entered. This can be 2 or 4 digits.
    */
    public static func validateYear(yearString: String)-> Bool {
        // Accept only digits.
        if(yearString.range(of: #"[^0-9]+"#,
        options: .regularExpression) != nil) {
            return false;
        }
        // Only years with a length of 2 or 4 are accepted.
        if (yearString.count != 2 && yearString.count != 4) {
            return false;
        }
        
        let currentYear = Calendar.current.component(.year, from: Date())
        let yearInt = Int(yearString)!;
        if (yearInt < currentYear || yearInt > currentYear + 50 ) {
            return false;
        }
        
        return true;
    }
    
    /**
     Checks if a valid month digit is entered
     */
    public static func validateMonth(monthString: String) -> Bool {
        // Accept only digits.
        if(monthString.range(of: #"[^0-9]+"#,
        options: .regularExpression) != nil) {
            return false;
        }
        // Only months with a length of 1 or 2 are accepted.
        if (monthString.count != 1 && monthString.count != 2) {
            return false;
        }
        // Check the value of month, it should be between 1 and 12.
        let monthInt = Int(monthString)!;
        if (monthInt < 1 || monthInt > 12) {
            return false;
        }
        return true;
    }

    /**
     Validates if the cardholder name is entered
     */
    public static func validateCardholderName(nameString: String) -> Bool {
        // Cardholder name should be filled.
        return nameString.count != 0 && nameString.range(of: #"\A\s*\z"#, options: .regularExpression) == nil
    }

    /**
     Validates the entered card number. The following checks are performed:
     1. Not empty
     2. Digits only
     3. Luhn check
     4. Card number matches the scheme pattern
     */
    public static func validateCardNumber(cardNumberString: String, cardBrand: CardBrand) -> Bool {
        if (cardNumberString == "") {
            return false;
        }
        // Accept only digits.
        if(cardNumberString.range(of: #"[^0-9]+"#
        , options: .regularExpression) != nil) {
            return false;
        }
        // Accept only card numbers with a length between 10 and 19.
        if (cardNumberString.count < 10 || cardNumberString.count > 19) {
            return false;
        }
        // The Luhn Algorithm.
        var sum = 0;
        for i in 0...cardNumberString.count - 1 {
            let char: Character = Array(cardNumberString)[i];
            var digit: Int = char.wholeNumberValue!;

            if (i % 2 == cardNumberString.count % 2) {
                digit *= 2;
                if (digit > 9) {
                    digit -= 9;
                }
            }
            sum += digit;
        }
        if (sum % 10 != 0) {
            return false;
        }
        else {
            switch (cardBrand) {
                case CardBrand.Bancontact:
                    return cardNumberString.range(of: #"^(4796|6060|6703|5613|5614)[0-9]{12,15}$"#
                    , options: .regularExpression) != nil;
                case CardBrand.Maestro:
                    return cardNumberString.range(of: #"^(5018|5020|5038|6304|6759|6761|6763)[0-9]{8,15}$"#
                    , options: .regularExpression) != nil;
                case CardBrand.Amex:
                    return cardNumberString.range(of: #"^3[47][0-9]{13}$"#
                    , options: .regularExpression) != nil;
                case CardBrand.Visa:
                    return cardNumberString.range(of: #"^4[0-9]{12}(?:[0-9]{3})?$"#
                    , options: .regularExpression) != nil;
                case CardBrand.Mastercard:
                    return cardNumberString.range(of: #"^(5[1-5]|2[2-7])[0-9]{14}$"#
                    , options: .regularExpression) != nil;
                default:
                    // Not a card service Buckaroo recognizes, so return false.
                    return false;
            }
        }
    }
    
    /**
        Returns the best guess for the card brand. In most cases tif he number of digits entered is below 4 CardType Unknown is returned
     */
    public static func predictCardType(cardNumberBeginning: String) -> CardBrand {
        if (cardNumberBeginning.range(of: #"^3"#, options: .regularExpression) != nil) {
            return CardBrand.Amex;
        }
        
        // This prevents a premature result on card numbers entered with a length below 4
        if (cardNumberBeginning.count < 4) {
            return CardBrand.Unknown;
        }
        
        if (cardNumberBeginning.range(of: #"^(5018|5020|5038|6304|6759|6761|6763)"#, options: .regularExpression) != nil) {
            return CardBrand.Maestro;
        }
        
        if (cardNumberBeginning.range(of: #"^(4796|6060|6703|5613|5614)"#, options: .regularExpression) != nil) {
            return CardBrand.Bancontact;
        }
        
        if (cardNumberBeginning.range(of: #"^4"#, options: .regularExpression) != nil) {
            return CardBrand.Visa;
        }
        
        if (cardNumberBeginning.range(of: #"^5"#, options: .regularExpression) != nil) {
            return CardBrand.Mastercard;
        }
        
        return CardBrand.Unknown;
    }
}
