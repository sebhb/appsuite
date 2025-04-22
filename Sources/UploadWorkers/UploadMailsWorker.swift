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

        var mails: [Data] = []

        for mailPath in paths {
            guard let mailData = try? Data(contentsOf: URL(fileURLWithPath: mailPath)) else { continue }
            mails.append(mailData)
        }

        let recipient = adjustRecipient ? self.recipient!.email1 : nil
        if (recipient != nil) || (stretchPeriod != nil) {
            let modifyWorker = EmailImportModifier(mails: mails, recipient: recipient, stretchPeriod: stretchPeriod)
            mails = modifyWorker.alteredMails()
        }

        for data in mails {
            try await importMail(mailData: data)
        }

        try await logout()
    }

    private func importMail(mailData: Data) async throws {
        let importMailCommand = ImportMailCommand(session: remoteSession, mailData: mailData)
        guard let _ = try await importMailCommand.execute() else {
            print("Could not upload mail.")
            return
        }
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
