//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 02.02.25.
//

import ArgumentParser
import Foundation

extension OXCloud {
    struct Users: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "users", abstract: "User related operations.", subcommands: [ListUsers.self, CreateUser.self])
    }

    struct ListUsers: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "list", abstract: "List all users in a context.")

        @OptionGroup var hostOptions: DataCenterOptions
        @OptionGroup var brandOptions: BrandOptions
        @OptionGroup var contextOptions: ContextNameOptions
        @OptionGroup var outputOptions: OutputFormatOptions

        mutating func run() async throws {
            let brandAuth = BrandAuth(brand: brandOptions.brandName, brandAuth: brandOptions.brandAuth)
            let listUsersCommand = ListUsersCommand(brandAuth: brandAuth, contextName: contextOptions.contextName, serverAddress: hostOptions.dataCenter.hostName())
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

    struct CreateUser: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "create", abstract: "Create a user in a context.")

        @OptionGroup var hostOptions: DataCenterOptions
        @OptionGroup var brandOptions: BrandOptions
        @OptionGroup var contextOptions: ContextNameOptions
        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var userCreationOptions: UserCreationOptions

        mutating func run() async throws {
            let brandAuth = BrandAuth(brand: brandOptions.brandName, brandAuth: brandOptions.brandAuth)
            let newUser = NewUser(name: userCredentialsOptions.userName, givenName: userCreationOptions.userGivenname, surName: userCreationOptions.userSurname, mail: userCreationOptions.email, password: userCredentialsOptions.password, classOfService: nil)
            let createUsersCommand = CreateUserCommand(brandAuth: brandAuth, contextName: contextOptions.contextName, newUser: newUser, serverAddress: hostOptions.dataCenter.hostName())
            do {
                let user = try await createUsersCommand.execute()
                if let user {
                    output(items: [user], format: .yaml)
                }
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }


}
