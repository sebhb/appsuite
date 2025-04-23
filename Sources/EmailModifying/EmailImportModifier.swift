import Foundation

struct DatedMail {
    let date: Date
    let mail: Data
}

class EmailImportModifier {
    var mails: [Data]
    let recipient: String?
    let stretchPeriod: Int?

    init(mails: [Data], recipient: String?, stretchPeriod: Int?) {
        self.mails = mails
        self.recipient = recipient
        self.stretchPeriod = stretchPeriod
    }

    func alteredMails() -> [Data] {
        if (recipient == nil) && (stretchPeriod == nil) {
            return mails
        }

        var randomDates = [Date]()
        if let stretchPeriod {
            for _ in 0..<mails.count {
                randomDates.append(Date.randomDateInPast(days: stretchPeriod))
            }
            randomDates.sort { $0 < $1 }
            sortMailsByDate()
        }

        var alteredMails: [Data] = []
        for mail in mails {
            guard let mailWorker = EmailWorker(email: mail) else {
                continue
            }
            mailWorker.rewrite(recipient: recipient, date: randomDates.removeFirst())
            let alteredMail = mailWorker.resultingMail()
            alteredMails.append(alteredMail)
        }

        return alteredMails
    }

    private func sortMailsByDate() {
        var mailsByDate: [DatedMail] = []
        for mail in mails {
            let worker = EmailWorker(email: mail)
            let date = worker?.mailDate() ?? Date.distantPast
            mailsByDate.append(DatedMail(date: date, mail: mail))
        }
        mailsByDate.sort { $0.date < $1.date }
        mails = mailsByDate.map() { $0.mail }
    }

}
