//
//  BoostController.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 01/04/2018.
//

import Foundation
import Vapor
import ErrorsCore
import ApiCore
import ImageCore


public class EinstoreController: Controller {
    
    /// BoostController error
    enum Error: FrontendError {
        
        /// Installation is required
        case installMissing
        
        /// Error code
        var identifier: String {
            return "boost.install_needed"
        }
        
        /// Reason for failure
        var reason: String {
            return "Admin team is missing! Have you run `/install` first?"
        }
        
        /// Errors HTTP status code
        var status: HTTPStatus {
            return .internalServerError
        }
    }
    
    /// Boot controller
    public static func boot(router: Router, secure: Router, debug: Router) throws {
        struct Mode: Content {
            let demo: Bool
        }
        
        router.get("mode") { req -> Mode in
            return Mode(demo: EinstoreCoreBase.configuration.demo)
        }
        
        // Install demo data
        debug.get("demo") { (req)->Future<Response> in
            return Team.query(on: req).first().flatMap(to: Response.self) { team in
                guard let team = team else {
                    throw Error.installMissing
                }
                var futures: [Future<Void>] = []
                // Install apps
                let appNames = ["RiverCity", "Superhero", "Goodlok", "Junior", "Road", "Shots", "Reflect", "Shack", "Muscle", "Army", "FirstStep", "Team", "Speak", "Shopping", "Sync", "Artist", "GoldCoast", "View", "Ponder", "Saver", "Americana", "Metro", "Lasso", "Fabric", "Experience", "Mates", "Trifecta", "SolidRock", "Upward", "Savers", "Vita", "North", "Renovation", "Anti", "Performance", "Boost", "Echelon", "HighPerformance", "Guild", "RedHot", "Rumble", "CarpeDiem", "Sapient", "Clone", "League", "Masters", "BlueSky", "Convergent", "Elite", "Upper", "Allied", "Bullseye", "Fixer", "Nano", "BestValue", "Wildlife", "Small", "River", "Doomsday", "Premiere", "Precision", "Mobi", "Under", "Rekola", "Supernova", "FirstCoast", "Department", "Copper", "Glory", "Player", "Friend", "FarEast", "Ambassador"]
                let platforms: [App.Platform] = [.ios, .android]
                for platform in platforms {
                    for name in appNames {
                        let identifier = "io.liveui.\(name.lowercased())"
                        var build = Int(Color.randomInt(max: 5000) + 1)
                        var cluster: Cluster? = nil
                        for i1 in 0...5 {
                            for i2 in 0...5 {
                                let version = "1.\(i1).\(i2)"
                                let sdk = "\(name)SDK_\(version)"
                                let sdk2 = "AnotherSDK_1.\(i2)"
                                let app = App(teamId: team.id!, clusterId: (cluster?.id ?? UUID()), name: name, identifier: identifier, version: version, build: String(build), platform: platform, built: Date(), size: 5000, sizeTotal: 5678, info: nil, minSdk: "19", hasIcon: false)
                                let save = app.save(on: req).flatMap(to: Void.self) { app in
                                    func saveTags() -> Future<Void> {
                                        let tags: [Future<Void>] = [
                                            Tag(teamId: team.id!, identifier: sdk.lowercased()).save(on: req).flatMap(to: Void.self) { tag in
                                                return app.tags.attach(tag, on: req).flatten()
                                            },
                                            Tag(teamId: team.id!, identifier: sdk2.lowercased()).save(on: req).flatMap(to: Void.self) { tag in
                                                return app.tags.attach(tag, on: req).flatten()
                                            }
                                        ]
                                        return tags.flatten(on: req)
                                    }
                                    guard let c = cluster else {
                                        let c = Cluster(latestApp: app, appCount: 1)
                                        cluster = c
                                        return c.save(on: req).flatMap({ c -> Future<Void> in
                                            guard let clusterId = c.id else {
                                                fatalError("Cluster didn't save")
                                            }
                                            cluster = c
                                            app.clusterId = clusterId
                                            return app.save(on: req).flatMap({ app -> Future<Void> in
                                                return saveTags()
                                            })
                                        })
                                    }
                                    c.appCount += 1
                                    return c.save(on: req).flatMap() { c in
                                        cluster = c
                                        return saveTags()
                                    }
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
