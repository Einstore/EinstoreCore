//
//  ApkInfo.swift
//  ApiCore
//
//  Created by Vojtěch Hrdina on 04/11/2018.
//

import Foundation

struct ApkInfo {
    
    var packageName: String?
    var versionCode: String?
    var versionName: String?
    var sdkVersion: String?
    var targetSdkVersion: String?
    var usesPermissions: [UsesPermission]?
    var applicationLabel: String?
    var applicationLabelTranslations: [(String, String)]?
    var applicationIcon: String?
    var applicationIconForDensity: [(String, String)]?
    var applicationIconRealPath: [String]?
    var usesFeatures: [UsesFeature]?
    var supportsScreens: [String]?
    var locales: [String]?
    var nativeCode: [String]?
    
    mutating func addPackageInfo(package: String) {
        let map = parseRawKeyValueData(rawData: package)
        map?.forEach {
            guard let parsedKeyValue = parseKeyValueData(keyValue: $0) else {
                return
            }
            let key = parsedKeyValue.0
            let value = parsedKeyValue.1
            
            switch true {
            case key == ParseKeys.name.rawValue:
                packageName = value
            case key == ParseKeys.name.rawValue:
                versionCode = value
            case key == ParseKeys.name.rawValue:
                versionName = value
                //            case key == ParseKeys.compileSdkVersion.rawValue
                //                compileSdkVersion = value
                //            case key == ParseKeys.parsedKeyValue.rawValue
            //                compileSdkVersionCodename = value
            default:
                return
            }
        }
    }
    
    mutating func addPermission(permission: String) {
        if(usesPermissions == nil) {
            self.usesPermissions = [UsesPermission]()
        }
        usesPermissions?.append(UsesPermission.init(name: permission, reason: nil))
    }
    
    mutating func addFeature(feature: String) {
        if(usesFeatures == nil) {
            self.usesFeatures = [UsesFeature]()
        }
        usesFeatures?.append(UsesFeature.init(name: feature, reason: nil))
    }
    
    mutating func addApplicationLabel(key: String, label: String) {
        if(key == ParseKeys.applicationLabel.rawValue) {
            self.applicationLabel = label
        } else {
            if(applicationLabelTranslations == nil) {
                self.applicationLabelTranslations = [(String, String)]()
            }
            
            let offset = key.count-ParseKeys.applicationLabel.rawValue.count-1
            let index1 = key.index(key.endIndex, offsetBy: -offset)
            let languageCode: String = String(key[index1...])
            self.applicationLabelTranslations?.append((languageCode, label))
        }
    }
    
    mutating func addApplicationIconForDensity(key: String, icon: String) {
        if(applicationIconForDensity == nil) {
            self.applicationIconForDensity = [(String, String)]()
        }
        
        let offset = key.count-ParseKeys.applicationIcon.rawValue.count-1
        let index1 = key.index(key.endIndex, offsetBy: -offset)
        let density: String = String(key[index1...])
        self.applicationIconForDensity?.append((density, icon))
    }
    
    mutating func addLocales(rawData: String) {
        let patternValue = "'(?:[^'\\\\]|\\\\.)*'"
        self.locales = matchValue(keyValue: rawData, pattern: patternValue)
    }
    
    mutating func addApplicationInfo(rawData: String) {
        let map = parseRawKeyValueData(rawData: rawData)
        map?.forEach {
            let parsedKeyValue = parseKeyValueData(keyValue: $0)
            if(parsedKeyValue != nil) {
                if(ParseKeys.label.rawValue == parsedKeyValue?.0) {
                    applicationLabel = parsedKeyValue?.1
                }
                if(ParseKeys.icon.rawValue == parsedKeyValue?.0) {
                    applicationIcon = parsedKeyValue?.1
                }
            }
        }
    }
    
    mutating func addSupportsScreens(rawData: String) {
        let patternValue = "'(?:[^'\\\\]|\\\\.)*'"
        self.supportsScreens = matchValue(keyValue: rawData, pattern: patternValue)
    }
    
    mutating func addNativeCode(rawData: String) {
        let patternValue = "'(?:[^'\\\\]|\\\\.)*'"
        self.nativeCode = matchValue(keyValue: rawData, pattern: patternValue)
    }
    
    mutating func setIconPath(path: [String]?) {
        self.applicationIconRealPath = path
    }
    
    func getIconName() -> String? {
        guard let iconName = applicationIcon else {
            return nil
        }
        let string = iconName as NSString
        let pattern = "(?:.(?!\\/))+\\."
        let regexValue = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: string.length)
        return regexValue?.firstMatch(in: iconName, options: [], range: range)
            .map {
                string.substring(with: $0.range).replacingOccurrences(of: "/", with: "").replacingOccurrences(of: ".", with: "")
        }
    }
    
    private func parseRawKeyValueData(rawData: String) -> [String]? {
        let string = rawData as NSString
        let pattern = "\\w+='(?:[^'\\\\]|\\\\.)*'"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        return regex?.matches(in: rawData, options: [], range: NSRange(location: 0, length: string.length)).map {
            string.substring(with: $0.range)
        }
    }
    
    //TODO return non optional values
    private func parseKeyValueData(keyValue: String) -> (String, String)? {
        let patternKey = "\\w+="
        let patternValue = "'(?:[^'\\\\]|\\\\.)*'"
        guard let key = parseValue(keyValue: keyValue, pattern: patternKey) else {
            return nil
        }
        guard let value = parseValue(keyValue: keyValue, pattern: patternValue) else {
            return nil
        }
        
        return (key, value)
    }
    
    private func matchValue(keyValue: String, pattern: String) -> [String]? {
        let string = keyValue as NSString
        let regexValue = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: string.length)
        return regexValue?.matches(in: keyValue, options: [], range: range)
            .map {
                string.substring(with: $0.range).replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "=", with: "")
        }
    }
    
    private func parseValue(keyValue: String, pattern: String) -> String? {
        return matchValue(keyValue: keyValue, pattern: pattern)?[0]
    }
    
    struct UsesFeature {
        let name: String
        let required: Bool = true
        let reason: String?
    }
    
    struct UsesPermission {
        let name: String
        let required: Bool = true
        let reason: String?
    }
    
    public enum ParseKeys: String, CaseIterable {
        case package = "package"
        case name = "name"
        case label = "label"
        case icon = "icon"
        case versionCode = "versionCode"
        case versionName = "versionName"
        case compileSdkVersion = "compileSdkVersion"
        case compileSdkVersionCodename = "compileSdkVersionCodename"
        case sdkVersion = "sdkVersion"
        case targetSdkVersion = "targetSdkVersion"
        case applicationLabel = "application-label"
        case applicationIcon = "application-icon"
        case application = "application"
        case usesPermission = "uses-permission"
        case usesImpliedPermission = "uses-implied-permission"
        case usesPermissionNotRequired = "uses-permission-not-required"
        case usesFeature = "uses-feature"
        case usesImpliedFeature = "uses-implied-feature"
        case usesFeatureNotRequired = "uses-feature-not-required"
        case supportsScreens = "supports-screens"
        case locales = "locales"
        case nativeCode = "native-code"
        
        public static var permissions: [ParseKeys] {
            return [
                usesPermission,
                usesImpliedPermission,
                usesPermissionNotRequired
            ]
        }
        
        public static func hasPermission(perm: String) -> Bool {
            let permission = permissions.first {$0.rawValue == perm}
            return permission != nil
        }
        
        public static var features: [ParseKeys] {
            return [
                usesFeature,
                usesImpliedFeature,
                usesFeatureNotRequired
            ]
        }
        
        public static func hasFeature(feature: String) -> Bool {
            let feature = features.first {$0.rawValue == feature}
            return feature != nil
        }
        
        public static func isLabel(key: String) -> Bool {
            return key.starts(with: ParseKeys.applicationLabel.rawValue)
        }
        
        public static func isDensityIcon(key: String) -> Bool {
            return key.starts(with: ParseKeys.applicationIcon.rawValue)
        }
    }
}
