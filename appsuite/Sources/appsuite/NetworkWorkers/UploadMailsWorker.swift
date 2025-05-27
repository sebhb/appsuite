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

        guard var mails = try loadMails(from: paths) else { return }

        let mailRecipient = adjustRecipient ? self.recipient!.email1 : nil
        if (mailRecipient != nil) || (stretchPeriod != nil) {
            let modifyWorker = EmailImportModifier(mails: mails, recipient: mailRecipient, stretchPeriod: stretchPeriod)
            mails = modifyWorker.alteredMails()
        }

        for mail in mails {
            try await uploadMail(mail)
        }

        try await logout()
    }

    private func loadMails(from paths: [String]) throws -> [Data]? {
        var mails: [Data] = []
        
        for mailPath in paths {
            guard let mailData = try? Data(contentsOf: URL(fileURLWithPath: mailPath)) else { continue }
            mails.append(mailData)
        }
        return mails
    }

    private func uploadMail(_ mailData: Data) async throws {
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
