//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 24.02.25.
//

import Foundation

class UploadMailsWorker: InfostoreBaseWorker {

    let adjustRecipient: Bool
    let stretchPeriod: Int?
    var recipient: Person?

    init(userCredentialsOptions: UserCredentialsOptions, adjustrecipient: Bool = false, stretchPeriod: Int? = nil) {
        self.adjustRecipient = adjustrecipient
        self.stretchPeriod = stretchPeriod
        super.init(userCredentialsOptions: userCredentialsOptions)
    }

    func uploadMails(paths: [String]) async throws {
        try await login()
        try await getUserSettings()

        for mailPath in paths {
            guard var mailData = try? Data(contentsOf: URL(fileURLWithPath: mailPath)) else { continue }

            if adjustRecipient || stretchPeriod != nil {
                guard let mailWorker = EmailWorker(email: mailData) else { continue }

                let recipient = adjustRecipient ? self.recipient!.email1 : nil
                let date = stretchPeriod != nil ? Date.randomDateInPast(days: stretchPeriod!) : nil

                mailWorker.rewrite(recipient: recipient, date: date)
                mailData = mailWorker.resultingMail()
            }

            let importMailCommand = ImportMailCommand(session: remoteSession, mailData: mailData)
            guard let _ = try await importMailCommand.execute() else {
                print("Could not upload mail.")
                return
            }
        }

        try await logout()
    }

    private func getUserSettings() async throws {
        guard adjustRecipient else { return }

        let getMeCommand = GetMeCommand(session: remoteSession)
        guard let me = try await getMeCommand.execute() else {
            print("Could not acquire calendar.")
            return
        }
        recipient = me.data
    }

    
}
