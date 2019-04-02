//
//  FlightCheck.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 07/08/2018.
//

import Foundation



/// Check protocol
public protocol Check {
    
    /// Verify check is passing
    var verification: (() -> FlightCheck.Result) { get }
    
}


/// Testing system readines for the job
public class FlightCheck {
    
    /// Result
    public struct Result {
        let success: Bool
        let failureMessage: String?
    }
    
    /// All available checks
    public internal(set) static var checks: [Check] = []
    
    /// Add a new check
    ///
    /// - Parameter check: Check
    public static func add(check: Check) {
        checks.append(check)
    }
    
    /// Launch verification
    public static func tick() {
        for check in checks {
            if check.verification().success == false {
                guard let message = check.verification().failureMessage else {
                    fatalError("Unknown error from: \(String(describing: check))")
                }
                fatalError(message)
            }
        }
    }
    
}
