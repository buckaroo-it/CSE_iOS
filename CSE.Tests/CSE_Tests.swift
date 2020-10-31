import XCTest
import CSE

class CSE_Tests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testValidateCardNumber() {
        let validateCardNumberResult = CSE.validateCardNumber(cardNumberString: "5386860000000000", cardBrand: CardBrand.Mastercard)
        assert(validateCardNumberResult)
    }
    
    func testValidateCardNumberLuhn() {
        let validateCardNumberResult = CSE.validateCardNumber(cardNumberString: "5386860000000001", cardBrand: CardBrand.Mastercard)
        assert(validateCardNumberResult == false)
    }
    
    func testValidateCardNumberBrand() {
        let validateCardNumberResult = CSE.validateCardNumber(cardNumberString: "5386860000000000", cardBrand: CardBrand.Visa)
        assert(validateCardNumberResult == false)
    }
    
    func testValidateCardholderNameResult() {
        let validateCardholderNameResult = CSE.validateCardholderName(nameString: "GROOT");
        assert(validateCardholderNameResult)
    }
    
    func testValidateCardholderNameResultEmpty() {
        let validateCardholderNameResult = CSE.validateCardholderName(nameString: "");
        assert(validateCardholderNameResult == false)
    }
    
    func testValidateCardholderNameResultWhitespace() {
        let validateCardholderNameResult = CSE.validateCardholderName(nameString: "       ");
        assert(validateCardholderNameResult == false)
    }
    
    func testValidateCardholderNameResultAlphaAndWhitespace() {
        let validateCardholderNameResult = CSE.validateCardholderName(nameString: "A B DE GROOT");
        assert(validateCardholderNameResult)
    }
    
    func testValidateMonthResult() {
        let validateMonthResult = CSE.validateMonth(monthString: "02");
        assert(validateMonthResult)
    }
    
    func testValidateMonthResult13() {
        let validateMonthResult = CSE.validateMonth(monthString: "13");
        assert(validateMonthResult == false)
    }
    
    func testValidateYearResult() {
        let validateYearResult = CSE.validateYear(yearString: "2020");
        assert(validateYearResult)
    }
    
    func testValidateYearResult2019() {
        let validateYearResult = CSE.validateYear(yearString: "2019");
        assert(validateYearResult == false)
    }
    
    func testValidateYearResult2100() {
        let validateYearResult = CSE.validateYear(yearString: "2100");
        assert(validateYearResult == false)
    }
    
    func testValidateCvcResult4() {
        let validateCvcResult = CSE.validateCvc(cvcString: "1234", cardBrand: CardBrand.Amex);
        assert(validateCvcResult)
    }
    
    func testValidateCvcResult3() {
        let validateCvcResult = CSE.validateCvc(cvcString: "123", cardBrand: CardBrand.Mastercard);
        assert(validateCvcResult)
    }
    
    func testValidateCvcResult1() {
        let validateCvcResult = CSE.validateCvc(cvcString: "1", cardBrand: CardBrand.Mastercard);
        assert(validateCvcResult == false)
    }
    
    func testEncryptCardDataResult() {
        do {
            let encryptCardDataResult = try CSE.encryptCardData(cardNumber: "5386860000000000", year: "2020", month: "12", cvc: "123", cardholder: "DE GROOT")
            print("encryptCardData: \(encryptCardDataResult)")
        } catch {
            print("encryptError: \(error)")
            assertionFailure(error.localizedDescription)
        }
    }
    
    func testPredictCardTypeBancontact() {
        let predictCardType = CSE.predictCardType(cardNumberBeginning: "6060")
        assert(predictCardType == CardBrand.Bancontact)
    }
    
    func testPredictCardTypeMaestro() {
        let predictCardType = CSE.predictCardType(cardNumberBeginning: "5020")
        assert(predictCardType == CardBrand.Maestro)
    }
    
    func testPredictCardTypeAmex() {
        let predictCardType = CSE.predictCardType(cardNumberBeginning: "333")
        assert(predictCardType == CardBrand.Amex)
    }
    
    func testPredictCardTypeVisa() {
        let predictCardType = CSE.predictCardType(cardNumberBeginning: "4444")
        assert(predictCardType == CardBrand.Visa)
    }
    
    func testPredictCardTypeMastercard() {
        let predictCardType = CSE.predictCardType(cardNumberBeginning: "5555")
        assert(predictCardType == CardBrand.Mastercard)
    }
}
