//
//  SQLFormatterTests.swift
//  Sidekick
//
//  Created on 2025-01-14.
//

import Testing
@testable import Sidekick

struct SQLFormatterTests {
    
    @Test("Format simple SELECT query")
    func formatSimpleSelect() {
        let input = "select * from users where id = 1"
        let output = SQLFormatter.format(input)
        
        #expect(output.contains("SELECT"))
        #expect(output.contains("FROM"))
        #expect(output.contains("WHERE"))
    }
    
    @Test("Format SELECT with multiple columns")
    func formatSelectMultipleColumns() {
        let input = "select id, name, email from users"
        let output = SQLFormatter.format(input)
        
        #expect(output.contains("SELECT"))
        #expect(output.contains("id"))
        #expect(output.contains("name"))
        #expect(output.contains("email"))
    }
    
    @Test("Format SELECT with JOIN")
    func formatSelectWithJoin() {
        let input = "select u.id, u.name, o.total from users u inner join orders o on u.id = o.user_id"
        let output = SQLFormatter.format(input)
        
        #expect(output.contains("SELECT"))
        #expect(output.contains("FROM"))
        #expect(output.contains("INNER JOIN"))
        #expect(output.contains("ON"))
    }
    
    @Test("Format SELECT with WHERE and AND")
    func formatSelectWithWhereAnd() {
        let input = "select * from users where age > 18 and status = 'active'"
        let output = SQLFormatter.format(input)
        
        #expect(output.contains("SELECT"))
        #expect(output.contains("FROM"))
        #expect(output.contains("WHERE"))
        #expect(output.contains("AND"))
    }
    
    @Test("Format SELECT with GROUP BY and ORDER BY")
    func formatSelectWithGroupByOrderBy() {
        let input = "select category, count(*) from products group by category order by count(*) desc"
        let output = SQLFormatter.format(input)
        
        #expect(output.contains("SELECT"))
        #expect(output.contains("FROM"))
        #expect(output.contains("GROUP BY"))
        #expect(output.contains("ORDER BY"))
    }
    
    @Test("Format complex query")
    func formatComplexQuery() {
        let input = "select u.id, u.name, count(o.id) as order_count from users u left join orders o on u.id = o.user_id where u.status = 'active' and u.created_at > '2024-01-01' group by u.id, u.name having count(o.id) > 5 order by order_count desc limit 10"
        let output = SQLFormatter.format(input)
        
        #expect(output.contains("SELECT"))
        #expect(output.contains("FROM"))
        #expect(output.contains("LEFT JOIN"))
        #expect(output.contains("WHERE"))
        #expect(output.contains("GROUP BY"))
        #expect(output.contains("HAVING"))
        #expect(output.contains("ORDER BY"))
        #expect(output.contains("LIMIT"))
    }
    
    @Test("Format empty string")
    func formatEmptyString() {
        let input = ""
        let output = SQLFormatter.format(input)
        
        #expect(output.isEmpty)
    }
    
    @Test("Format whitespace only")
    func formatWhitespaceOnly() {
        let input = "   \n\t  "
        let output = SQLFormatter.format(input)
        
        #expect(output.isEmpty)
    }
    
    @Test("Preserve case for non-keywords")
    func preserveCaseForNonKeywords() {
        let input = "select UserName, EmailAddress from MyTable"
        let output = SQLFormatter.format(input)
        
        #expect(output.contains("UserName"))
        #expect(output.contains("EmailAddress"))
        #expect(output.contains("MyTable"))
    }
}
