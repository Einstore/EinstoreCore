//
//  BoostController.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 01/04/2018.
//

import Foundation
import Vapor
import ErrorsCore
import ApiCore


public class BoostController: Controller {
    
    enum Problem: FrontendError {
        case installMissing
        
        var code: String {
            return "boost_error"
        }
        
        var description: String {
            return "Admin team is missing! Have you run `/install` first?"
        }
        
        var status: HTTPStatus {
            return .internalServerError
        }
    }

    public static func boot(router: Router) throws {
        router.get("info") { req -> Future<Response> in
            let info: [String: String] = [
                "name": Environment.get("BOOST_NAME") ?? "Boost",
                "url": req.serverURL().absoluteString
            ]
            let response = try info.asJson().asResponse(.ok, to: req)
            return response
        }
        
        router.get("demo") { (req)->Future<Response> in
            return Team.query(on: req).first().flatMap(to: Response.self) { team in
                guard let team = team else {
                    throw Problem.installMissing
                }
                var futures: [Future<Void>] = []
                // Install apps
                let appNames = ["RiverCity", "Superhero", "Goodlok", "Junior", "Road", "Shots", "Reflect", "Shack", "Muscle", "Army", "FirstStep", "Team", "Speak", "Shopping", "Sync", "Artist", "GoldCoast", "View", "Ponder", "Saver", "Americana", "Metro", "Lasso", "Fabric", "Experience", "Mates", "Trifecta", "SolidRock", "Upward", "Savers", "Vita", "North", "Renovation", "Anti", "Performance", "Boost", "Echelon", "HighPerformance", "Guild", "RedHot", "Rumble", "CarpeDiem", "Sapient", "Clone", "League", "Masters", "BlueSky", "Convergent", "Elite", "Upper", "Allied", "Bullseye", "Fixer", "Nano", "BestValue", "Wildlife", "Small", "River", "Doomsday", "Premiere", "Precision", "Mobi", "Under", "Rekola", "Supernova", "FirstCoast", "Department", "Copper", "Glory", "Player", "Friend", "FarEast", "Ambassador"]
                let platforms: [App.Platform] = [.ios, .android]
                for platform in platforms {
                    for name in appNames {
                        let identifier = "io.liveui.\(name.lowercased())"
                        var build = Int(arc4random_uniform(5000) + 1)
                        for i1 in 0...10 {
                            for i2 in 0...10 {
                                let version = "1.\(i1).\(i2)"
                                let sdk = "\(name)SDK_\(version)"
                                let sdk2 = "AnotherSDK_1.\(i2)"
                                let app = App(teamId: team.id!, name: name, identifier: identifier, version: version, build: String(build), platform: platform, info: nil, hasIcon: false)
                                let save = app.save(on: req).flatMap(to: Void.self) { app in
                                    let tags: [Future<Void>] = [
                                        Tag(name: sdk, identifier: sdk.lowercased()).save(on: req).flatMap(to: Void.self) { tag in
                                            return app.tags.attach(tag, on: req).flatten()
                                        },
                                        Tag(name: sdk2, identifier: sdk2.lowercased()).save(on: req).flatMap(to: Void.self) { tag in
                                            return app.tags.attach(tag, on: req).flatten()
                                        }
                                    ]
                                    return tags.flatten(on: req)
                                }
                                futures.append(save)
                                build += 1
                            }
                        }
                    }
                }
                return futures.flatten(on: req).map(to: Response.self) { _ in
                    return try req.response.maintenanceFinished(message: "Demo ready for inspection captain!")
                }
            }
        }
    }
    
}
