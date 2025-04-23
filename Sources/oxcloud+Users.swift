import ArgumentParser
import Foundation

extension OXCloud {
    struct Users: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "users", abstract: "User related operations.", subcommands: [ListUsers.self, GetUser.self, CreateUser.self, AlterClassOfServiceUser.self, CreateTokenLoginUser.self])
    }

    struct ListUsers: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "list", abstract: "List all users in a context.")

        @OptionGroup var brandOptions: BrandOptions
        @OptionGroup var contextOptions: ContextNameOptions
        @OptionGroup var outputOptions: OutputFormatOptions

        mutating func run() async throws {
            let brandAuth = BrandAuth(brand: brandOptions.brandName!, brandAuth: brandOptions.brandAuth!)
            let listUsersCommand = ListUsersCommand(brandAuth: brandAuth, contextName: contextOptions.contextName, serverAddress: brandOptions.dataCenter!.hostName())
            do {
                let users = try await listUsersCommand.execute()
                if let users {
                    output(items: users.items, format: outputOptions.format)
                }
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

    struct GetUser: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "get", abstract: "Gets a user by username in a context.")

        @OptionGroup var brandOptions: BrandOptions
        @OptionGroup var contextOptions: ContextNameOptions
        @OptionGroup var searchOptions: SearchOptions

        mutating func run() async throws {
            let brandAuth = BrandAuth(brand: brandOptions.brandName!, brandAuth: brandOptions.brandAuth!)
            let getUserCommand = GetUserCommand(brandAuth: brandAuth, contextName: contextOptions.contextName, usernameQuery: searchOptions.query, serverAddress: brandOptions.dataCenter!.hostName())
            do {
                let user = try await getUserCommand.execute()
                if let user {
                    output(item: user)
                }
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

    struct CreateUser: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "create", abstract: "Create a user in a context.")

        @OptionGroup var brandOptions: BrandOptions
        @OptionGroup var contextOptions: ContextNameOptions
        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var userCreationOptions: UserCreationOptions

        mutating func run() async throws {
            let brandAuth = BrandAuth(brand: brandOptions.brandName!, brandAuth: brandOptions.brandAuth!)
            let newUser = NewUser(name: userCredentialsOptions.userName, givenName: userCreationOptions.userGivenname, surName: userCreationOptions.userSurname, mail: userCreationOptions.email, password: userCredentialsOptions.password, classOfService: nil)
            let createUsersCommand = CreateUserCommand(brandAuth: brandAuth, contextName: contextOptions.contextName, newUser: newUser, serverAddress: brandOptions.dataCenter!.hostName())
            do {
                let user = try await createUsersCommand.execute()
                if let user {
                    output(item: user)
                }
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

    struct AlterClassOfServiceUser: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "cos", abstract: "Alter class of service for a user in a context.")

        @OptionGroup var brandOptions: BrandOptions
        @OptionGroup var contextOptions: ContextNameOptions
        @OptionGroup var userNameOptions: UserNameOptions
        @OptionGroup var classesOfServiceOptions: ClassOfServiceOptions

        mutating func run() async throws {
            let brandAuth = BrandAuth(brand: brandOptions.brandName!, brandAuth: brandOptions.brandAuth!)

            var classesToSet: [String] = []

            if classesOfServiceOptions.classesToSet.count > 0 {
                classesToSet = classesOfServiceOptions.classesToSet
            }
            else {
                let getUserCommand = GetUserCommand(brandAuth: brandAuth, contextName: contextOptions.contextName, usernameQuery: userNameOptions.userName, serverAddress: brandOptions.dataCenter!.hostName())
                do {
                    let user = try await getUserCommand.execute()
                    if let user {
                        classesToSet = (user.classOfService ?? []) + classesOfServiceOptions.classesToAdd
                    }
                }
                catch {
                    print("An error occurred: \(error)")
                }
            }

            let changeCosCommand = AlterUserCOSCommand(brandAuth: brandAuth, contextName: contextOptions.contextName, username: userNameOptions.userName, classesOfService: classesToSet, serverAddress: brandOptions.dataCenter!.hostName())
            do {
                let result = try await changeCosCommand.execute()
                if let _ = result {
                    print("Classes of service altered successfully.")
                }
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

    struct CreateTokenLoginUser: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "createtokenlogin", abstract: "Create a token login URL for a user.")

        @OptionGroup var userCredentials: UserCredentialsOptions

        mutating func run() async throws {
            let createTokenLoginCommand = CreateTokenLoginCommand(username: userCredentials.userName, password: userCredentials.password, serverAddress: userCredentials.server)
            do {
                let url = try await createTokenLoginCommand.execute()
                if let url {
                    print(url)
                }
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

}
