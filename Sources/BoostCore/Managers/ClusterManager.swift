//
//  ClusterManager.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 28/12/2018.
//

import Foundation
import Vapor
import ApiCore
import ErrorsCore
import Fluent
import FluentPostgreSQL
import DatabaseKit
import SQL


public class ClusterManager {
    
    public static func cluster(for appIdentifier: String, platform: App.Platform, teamId: DbIdentifier, on req: Request) -> EventLoopFuture<Cluster?> {
        return Cluster.query(on: req)
            .filter(\Cluster.identifier == appIdentifier)
            .filter(\Cluster.platform == platform)
            .filter(\Cluster.teamId == teamId)
            .first()
    }
    
}
