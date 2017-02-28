import Vapor
import VaporMySQL
import Auth
import Sessions
import Fluent
import FluentMySQL

let drop = Droplet()

try drop.addProvider(VaporMySQL.Provider.self)
drop.preparations.append(User.self)
drop.preparations.append(Shot.self)
drop.preparations.append(Pivot<Shot, Category>.self)
drop.preparations.append(Category.self)
drop.preparations.append(Like.self)

let memory = MemorySessions()
let sessions = SessionsMiddleware(sessions: memory)
drop.middleware.append(sessions)

let auth = AuthMiddleware(user: User.self)
drop.middleware.append(auth)

let login = LoginController()
login.addRoutes(to: drop)

let admin = AdminController()
admin.addRoutes(to: drop)

let adminCreators = AdminCreatorsController()
adminCreators.addRoutes(to: drop)

drop.group(ProtectMiddleware()) { secure in
    drop.resource("api/shots", ShotController())
    drop.resource("api/likes", LikeController())
}

drop.run()
