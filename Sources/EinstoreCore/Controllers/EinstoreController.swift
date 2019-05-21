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
                let appNames = ["RiverCity", "Superhero", "Goodlok"]//, "Junior", "Road", "Shots", "Reflect", "Shack", "Muscle", "Army", "FirstStep", "Team", "Speak", "Shopping", "Sync", "Artist", "GoldCoast", "View", "Ponder", "Saver", "Americana", "Metro", "Lasso", "Fabric", "Experience", "Mates", "Trifecta", "SolidRock", "Upward", "Savers", "Vita", "North", "Renovation", "Anti", "Performance", "Boost", "Echelon", "HighPerformance", "Guild", "RedHot", "Rumble", "CarpeDiem", "Sapient", "Clone", "League", "Masters", "BlueSky", "Convergent", "Elite", "Upper", "Allied", "Bullseye", "Fixer", "Nano", "BestValue", "Wildlife", "Small", "River", "Doomsday", "Premiere", "Precision", "Mobi", "Under", "Rekola", "Supernova", "FirstCoast", "Department", "Copper", "Glory", "Player", "Friend", "FarEast", "Ambassador"]
                let platforms: [Build.Platform] = [.ios, .android]
                for platform in platforms {
                    for name in appNames {
                        let cluster = Cluster(
                            id: nil,
                            latestBuild: Build(
                                id: UUID(),
                                teamId: UUID(),
                                clusterId: UUID(),
                                name: "",
                                identifier: "",
                                version: "",
                                build: "",
                                platform: .ios,
                                built: nil,
                                size: 0,
                                sizeTotal: 0
                            ),
                            appCount: 0
                        )
                        let future = cluster.save(on: req).flatMap(to: Void.self) { cluster in
                            let client = try req.make(Client.self)
                            return client.get("https://api.adorable.io/avatars/256/\(name.lowercased())@\(name.lowercased()).io.png").flatMap(to: Void.self) { icon in
                                let hasIcon = (icon.http.status == .ok && icon.http.body.data != nil)
                                let identifier = "io.liveui.\(name.lowercased())"
                                var buildNumber = Int(Color.randomInt(max: 5000) + 1)
                                for i1 in 0...Color.randomInt(max: 4) {
                                    for i2 in 0...Color.randomInt(max: 6) {
                                        let version = "1.\(i1).\(i2)"
                                        let sdk = "\(name)SDK_\(version)"
                                        let sdk2 = "AnotherSDK_1.\(i2)"
                                        
                                        let commitId = UUID()
                                        let prId = UUID()
                                        let pmId = UUID()
                                        
                                        let iconDataMD5 = try icon.http.body.data?.asMD5String()
                                        
                                        let build = Build(
                                            teamId: team.id!,
                                            clusterId: cluster.id!,
                                            name: name,
                                            identifier: identifier,
                                            version: version,
                                            build: String(buildNumber),
                                            platform: platform,
                                            built: Date(),
                                            size: 5000,
                                            sizeTotal: 5678,
                                            info: Build.Info(
                                                sourceControl: Build.Info.SourceControl(
                                                    commit: Build.Info.URLMessagePair(
                                                        id: commitId.uuidString,
                                                        url: "https://github.example.com/team/project/commit/\(commitId.uuidString)",
                                                        message: "Lorem implemented"
                                                    ),
                                                    pr: Build.Info.URLMessagePair(
                                                        id: prId.uuidString,
                                                        url: "https://github.example.com/team/project/pr/\(prId.uuidString)",
                                                        message: "Lorem ipsum dolor sit amet has been implemented"
                                                    )
                                                ),
                                                projectManagement: Build.Info.ProjectManagement(
                                                    ticket: Build.Info.URLMessagePair(
                                                        id: pmId.uuidString,
                                                        url: "https://project.example.com/ticket/\(pmId.uuidString)",
                                                        message: "Lorem ipsum dolor sit amet needs to be implemented properly in order for the system to work.\n\nLook at lipsum.org for details!"
                                                    )
                                                )
                                            ),
                                            minSdk: "19",
                                            iconHash: iconDataMD5
                                        )
                                        let save = build.save(on: req).flatMap(to: Void.self) { build in
                                            func saveTags() -> Future<Void> {
                                                let tags: [Future<Void>] = [
                                                    Tag(teamId: team.id!, identifier: sdk.lowercased()).save(on: req).flatMap(to: Void.self) { tag in
                                                        return build.tags.attach(tag, on: req).flatten()
                                                    },
                                                    Tag(teamId: team.id!, identifier: sdk2.lowercased()).save(on: req).flatMap(to: Void.self) { tag in
                                                        return build.tags.attach(tag, on: req).flatten()
                                                    }
                                                ]
                                                return tags.flatten(on: req)
                                            }
                                            cluster.identifier = build.identifier
                                            cluster.platform = build.platform
                                            cluster.teamId = build.teamId
                                            cluster.buildCount += 1
                                            return cluster.add(build: build, on: req).flatMap() { cluster in
                                                guard icon.http.status == .ok, let iconData = icon.http.body.data, let path = build.iconPath?.relativePath else {
                                                    print("Demo app icon has not been generated")
                                                    return saveTags()
                                                }
                                                return try build.save(iconData: iconData, on: req).flatMap() { _ in
                                                    print("Demo app icon has been generated to \(path)")
                                                    return saveTags()
                                                }
                                            }
                                        }
                                        futures.append(save)
                                        buildNumber += 1
                                    }
                                }
                                return futures.flatten(on: req)
                            }
                        }
                        futures.append(future)
                    }
                }
                return futures.flatten(on: req).map(to: Response.self) { _ in
                    return try req.response.maintenanceFinished(message: "Demo ready for inspection captain!")
                }
            }
        }
    }
    
}
