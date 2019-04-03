//
//  AppNotificationEmailTemplate.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 02/03/2019.
//

import Foundation
import ApiCore


public class AppNotificationEmailTemplate: EmailTemplate {
    
    public static var name: String = "app-notification-email"
    
    public static var string: String = """
        Hi #(user.firstname) #(user.lastname)
        
        To download #(app.name), version #(app.version)(#(app.build)) for #(app.platform) click here #(link)
        
        Einstore team
        """
    
    public static var html: String? = """
        <h1>Hi #(user.firstname) #(user.lastname)</h1>
        <p>&nbsp;</p>
        <p>To download #(app.name), version #(app.version)(#(app.build)) for #(app.platform) click here <a href="#(link)">link</a></p>
        <p>&nbsp;</p>
        <p>Full link is: <strong>#(link)</strong></p>
        <p>&nbsp;</p>
        <p>Einstore team</p>
        """
    
}
