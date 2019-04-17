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
    
    public static var link: String = ""
    
    public static var deletable: Bool = false
    
}


public class EmailAppNotificationEmailPlain: Source {
    
    public typealias Database = ApiCoreDatabase
    
    public static var name: String = "email.app-notification.plain"
    
    public static var link: String = ""
    
    public static var deletable: Bool = false
    
}
