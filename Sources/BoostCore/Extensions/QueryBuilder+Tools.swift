//
//  QueryBuilder+Tools.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 26/04/2018.
//

import Foundation
import Fluent
import FluentSQL
import DatabaseKit
import SQL


extension QueryBuilder {

    public func resetColumns() -> Self {
        return customSQL({ query in
            switch query {
            case .query(var q):
                q.columns.removeAll()
                query = .query(q)
            default:
                return
            }
        })
    }
    
    public func select(_ columns: String...) -> Self {
        return customSQL({ query in
            switch query {
            case .query(var q):
                for column in columns {
                    q.columns.append(DataQueryColumn.column(DataColumn(name: column), key: nil))
                }
                query = .query(q)
            default:
                return
            }
        })
    }
    
    public func computed(_ columns: String...) -> Self {
        return customSQL({ query in
            switch query {
            case .query(var q):
                for column in columns {
                    q.columns.append(DataQueryColumn.computed(DataComputedColumn(function: column), key: nil))
                }
                query = .query(q)
            default:
                return
            }
        })
    }
    
    public func computed(_ columns: (function: String, columns: [DataColumn], key: String?)...) -> Self {
        return customSQL({ query in
            switch query {
            case .query(var q):
                for column in columns {
                    q.columns.append(DataQueryColumn.computed(DataComputedColumn(function: column.function, columns: column.columns), key: column.key))
                }
                query = .query(q)
            default:
                return
            }
        })
    }
    
    public func computed(_ columns: (function: String, key: String)...) -> Self {
        return customSQL({ query in
            switch query {
            case .query(var q):
                for column in columns {
                    q.columns.append(DataQueryColumn.computed(DataComputedColumn(function: column.function), key: column.key))
                }
                query = .query(q)
            default:
                return
            }
        })
    }
    
    public func group(by columns: String...) -> Self {
        return customSQL({ query in
            switch query {
            case .query(var query):
                for column in columns {
                    query.groupBys.append(DataGroupBy.column(DataColumn(name: column)))
                }
            default:
                return
            }
        })
    }
    
    public func printSqlString() -> Self {
        return customSQL({ query in
            let serializer = GeneralSQLSerializer.init()
            switch query {
            case .query(let query):
                print(serializer.serialize(query: query))
            default:
                print(":(")
            }
        })
    }
    
}
