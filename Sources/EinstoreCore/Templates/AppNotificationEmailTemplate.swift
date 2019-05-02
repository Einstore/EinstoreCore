//
//  AppNotificationEmailTemplate.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 02/03/2019.
//

import Foundation
import ApiCore
import Templator


public class EmailAppNotificationTemplateHTML: Source {
    
    public typealias Database = ApiCoreDatabase
    
    public static var name: String = "email.app-notification.html"
    
    public static var link: String = "https://raw.githubusercontent.com/Einstore/EinstoreCore/master/Resources/Templates/email.app-notification.html.leaf"
    
    public static var deletable: Bool = false
    
}


public class EmailAppNotificationEmailPlain: Source {
    
    public typealias Database = ApiCoreDatabase
    
    public static var name: String = "email.app-notification.plain"
    
    public static var link: String = "https://raw.githubusercontent.com/Einstore/EinstoreCore/master/Resources/Templates/email.app-notification.plain.leaf"
    
    public static var deletable: Bool = false
    
}
