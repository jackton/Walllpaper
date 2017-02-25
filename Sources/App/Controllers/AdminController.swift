//
//  AdminController.swift
//  Walllpaper
//
//  Created by Maxime De Greve on 20/02/2017.
//
//

import Vapor
import HTTP
import Turnstile
import Auth
import Fluent

final class AdminController {

    func addRoutes(to drop: Droplet) {

        drop.group(AdminProtectMiddleware()) { secure in
            
            secure.get("admin", handler: index)
            secure.post("admin", handler: post)
            secure.get("admin","delete", handler: delete)
            secure.get("admin","creators", handler: creators)
            secure.post("admin","category", handler: categoryPost)
            
        }

    }
    
    func getShots() throws -> [Shot]{
        
        let shotsQuery = try Shot.query()
        shotsQuery.limit = Limit(count: 42, offset: 0)
        let shots = try shotsQuery.sort("created_at", .descending).all()
        return shots
        
    }
    
    func getCategories() throws -> [Category]{
        
        return try Category.query().all()
        
    }
    
    func index(_ request: Request) throws -> ResponseRepresentable {

        return try drop.view.make("admin", [
                "shots": try getShots().makeNode(),
                "categories": try getCategories().makeNode(),
                ])
        
    }
    
    func delete(_ request: Request) throws -> ResponseRepresentable {
        
        guard let shotID = request.data["shot-id"]?.int else {
            throw Abort.badRequest
        }
        
        guard let shot = try Shot.find(shotID) else {
            throw Abort.badRequest
        }
        
        try shot.delete()
        
        return Response(redirect: "/admin")
    }
    
    func categoryPost(_ request: Request) throws -> ResponseRepresentable {
        
        guard let shotID = request.data["shot-id"]?.int else {
            throw Abort.badRequest
        }
        
        guard let shot = try Shot.find(shotID) else {
            throw Abort.badRequest
        }
        
        guard let categoryID = request.data["category-id"]?.int else {
            throw Abort.badRequest
        }
        
        guard let category = try Category.find(categoryID) else {
            throw Abort.badRequest
        }
        
        var pivot = Pivot<Shot, Category>(shot, category)   // Create the relationship
        try pivot.save()
                
        return Response(status: .created, body: "Added to category...")
    }
    
    func post(_ request: Request) throws -> ResponseRepresentable {
        
        if let shotId = request.data["shot-id"]?.int{
            
            let response = try Dribbble.shot(token: Dribbble.access_token, id: shotId)
            
            guard let shotData = response.json?.object else {
                throw Abort.badRequest
            }
            
            var shot = try Shot.dribbbleData(data: shotData)
            try shot.save()
            
        }
        
        return Response(redirect: "/admin")
    }
    
    func creators(_ request: Request) throws -> ResponseRepresentable {
        
        let users = try User.withShots().makeNode()
                
        return try drop.view.make("admin-creator", [
            "users": users,
            ])
        
    }
    
}
