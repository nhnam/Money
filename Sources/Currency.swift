//
// Money, https://github.com/danthorpe/Money
// Created by Dan Thorpe, @danthorpe
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Daniel Thorpe
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

/**
 # CurrencyType
 This protocol defines the minimum interface needed for a 
 CurrencyType.
 
 The interface used to represent a single currency. Note
 that it is always used as a generic constraint on other
 types.
 
 Typically framework consumers will not need to conform to
 this protocol, unless creating their own currencies. See
 the example project "Custom Money" for an example of this.
*/
public protocol CurrencyType: DecimalNumberBehaviorType {

    /// The currency code
    static var code: String { get }

    /// The currency scale
    static var scale: Int { get }

    /// The currency symbol
    static var symbol: String? { get }

    /// Default formatting style
    static var defaultFormattingStyle: NumberFormatter.Style { get }
    
    static func formatted(withStyle: NumberFormatter.Style, forLocaleId localeId: String) -> (NSDecimalNumber) -> String

    static func formatted(withStyle: NumberFormatter.Style, forLocale locale: NSLocale) -> (NSDecimalNumber) -> String
}

public extension CurrencyType {

    static var defaultFormattingStyle: NumberFormatter.Style {
        return .currency
    }
    
    /**
     Default implementation of the `NSDecimalNumberBehaviors` for
     the currency. This uses `NSRoundingMode.RoundBankers` and the
     scale of the currency as given by the localized formatter.
     
     - returns: a `NSDecimalNumberBehaviors`
    */
    static var decimalNumberBehaviors: NSDecimalNumberBehaviors {
        return NSDecimalNumberHandler(
            roundingMode: .bankers,
            scale: Int16(scale),
            raiseOnExactness: true,
            raiseOnOverflow: true,
            raiseOnUnderflow: true,
            raiseOnDivideByZero: true
        )
    }

    static func formatted(withStyle style: NumberFormatter.Style, forLocale tmp: NSLocale) -> (NSDecimalNumber) -> String {

        let id = "\(tmp.localeIdentifier)@currency=\(code)"
        let canonical = NSLocale.canonicalLocaleIdentifier(from: id)
        let nslocale = NSLocale(localeIdentifier: canonical)
        let locale = Locale(identifier: canonical)

        let formatter = NumberFormatter()
        formatter.currencyCode = code
        formatter.locale = locale
        formatter.numberStyle = style
        formatter.maximumFractionDigits = scale
        formatter.currencySymbol = symbol ?? nslocale.mny_currencySymbol
        
        return { formatter.string(from: $0)! }
    }
}

/**
 Custom currency types should refine CustomCurrencyType.

 This is to benefit from default implementations of string
 formatting.
*/
public protocol CustomCurrencyType: CurrencyType { }

public extension CustomCurrencyType {

    /**
     Use the provided locale identifier to format a supplied NSDecimalNumber.
     
     - returns: a NSDecimalNumber -> String closure.
    */
    static func formatted(withStyle style: NumberFormatter.Style, forLocaleId localeId: String) -> (NSDecimalNumber) -> String {
        let locale = NSLocale(localeIdentifier: NSLocale.canonicalLocaleIdentifier(from: localeId))
        return formatted(withStyle: style, forLocale: locale)
    }

    /**
     Use the provided Local to format a supplied NSDecimalNumber.

     - returns: a NSDecimalNumber -> String closure.
     */
    static func formatted(withStyle style: NumberFormatter.Style, forLocale locale: MNYLocale) -> (NSDecimalNumber) -> String {
        return formatted(withStyle: style, forLocaleId: locale.localeIdentifier)
    }
}

/**
 Crypto currency types (Bitcoin etc) should refine CryptoCurrencyType.

 This is to benefit from default implementations.
*/
public protocol CryptoCurrencyType: CustomCurrencyType { }

/**
 `ISOCurrencyType` is a refinement of `CurrencyType` so that
 the ISO currencies can be autogenerated.
*/
public protocol ISOCurrencyType: CurrencyType {

    /** 
     A shared instance of the currency. Note that static
     variables are lazily created.
    */
    static var sharedInstance: Self { get }

    /// - returns: the currency code
    var _code: String { get }

    /// - returns: the currency scale
    var _scale: Int { get }
    
    /// - returns: the currency symbol
    var _symbol: String? { get }
    
}

public extension ISOCurrencyType {

    /// The currency code
    static var code: String {
        return sharedInstance._code
    }

    /// The currency scale
    static var scale: Int {
        return sharedInstance._scale
    }

    /// The currency symbol
    static var symbol: String? {
        return sharedInstance._symbol
    }

    /**
     Use the provided locale identifier to format a supplied NSDecimalNumber.

     - returns: a NSDecimalNumber -> String closure.
     */
    static func formatted(withStyle style: NumberFormatter.Style, forLocaleId localeId: String) -> (NSDecimalNumber) -> String {
        let id = "\(NSLocale.current.identifier)@currency=\(code)"
        let locale = NSLocale(localeIdentifier: NSLocale.canonicalLocaleIdentifier(from: id))
        return formatted(withStyle: style, forLocale: locale)
    }

    /**
     Use the provided Local to format a supplied NSDecimalNumber.

     - returns: a NSDecimalNumber -> String closure.
     */
    static func formatted(withStyle style: NumberFormatter.Style, forLocale locale: MNYLocale) -> (NSDecimalNumber) -> String {
        let id = "\(locale.localeIdentifier)@currency=\(code)"
        let locale = NSLocale(localeIdentifier: NSLocale.canonicalLocaleIdentifier(from: id))
        return formatted(withStyle: style, forLocale: locale)
    }
}

/**
 # Currency
 A namespace for currency related types.
*/
public struct Currency {

    /**

     # Currency.Base
     
     `Currency.Base` is a class which composes a number formatter
     and a locale. It doesn't conform to `CurrencyType` but it can
     be used as a base class for currency types which only require
     a shared instance.
     */
    public class Base {

        public let _code: String
        public let _scale: Int
        public let _symbol: String?

        init(code: String, scale: Int, symbol: String?) {
            _code = code
            _scale = scale
            _symbol = symbol
        }

        convenience init(code: String) {
            let idFromComponents = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code])
            let canonical = NSLocale.canonicalLocaleIdentifier(from: idFromComponents)
            let nslocale = NSLocale(localeIdentifier: canonical)
            let locale = Locale(identifier: canonical)
            let symbol = nslocale.mny_currencySymbol!
            
            let fmtr = NumberFormatter()
            fmtr.locale = locale
            fmtr.numberStyle = .currency
            fmtr.currencyCode = code
            fmtr.currencySymbol = nslocale.mny_currencySymbol
            
            let scale = fmtr.maximumFractionDigits
            self.init(code: code, scale: scale, symbol: symbol)
        }
        
        convenience init(locale: NSLocale) {
            let code = locale.mny_currencyCode!
            let symbol = locale.mny_currencySymbol
            
            let fmtr = NumberFormatter()
            fmtr.numberStyle = .currency
            fmtr.locale = Locale(identifier: locale.localeIdentifier)
            fmtr.currencyCode = code
            
            let scale = fmtr.maximumFractionDigits            
            self.init(code: code, scale: scale, symbol: symbol)
        }
    }

    /**
     
     # Currency.Local
     
     `Currency.Local` is a `BaseCurrency` subclass which represents
     the device's current currency, using `NSLocale.currentLocale()`.
     */
    public final class Local: Currency.Base, ISOCurrencyType {
        public static var sharedInstance = Local(locale: NSLocale.current as NSLocale)
    }
}
