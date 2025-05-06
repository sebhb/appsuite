import Foundation

class AppointmentGenerator {

    let startDate: Date
    let endDate: Date
    let contacts: [Person]
    let locale: Locale

    var appointmentDesciptions: [AppointmentTemplate]

    /// Returns a generator for the time frame -days from now until +days into the future
    static func generator(days: Int, appointmentDesciptions: [AppointmentTemplate], contacts: [Person], locale: Locale) -> AppointmentGenerator {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()

        let firstDay = calendar.date(byAdding: .day, value: -days, to: now)!
        let lastDay = calendar.date(byAdding: .day, value: days, to: now)!

        return AppointmentGenerator(startDate: firstDay, endDate: lastDay, appointmentDesciptions: appointmentDesciptions, contacts: contacts, locale: locale)
    }

    init(startDate: Date, endDate: Date, appointmentDesciptions: [AppointmentTemplate], contacts: [Person], locale: Locale) {
        self.startDate = startDate
        self.endDate = endDate
        self.appointmentDesciptions = appointmentDesciptions
        self.contacts = contacts
        self.locale = locale
    }

    func generateAppointments() -> [AppointmentRequest] {
        var result: [AppointmentRequest] = []

        let calendar = Calendar(identifier: .gregorian)
        var currentDate = startDate
        
        while currentDate < endDate {
            result.append(contentsOf: appointmentsForDay(currentDate))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return result
    }

    func appointmentsForDay(_ day: Date) -> [AppointmentRequest] {
        var result: [AppointmentRequest] = []

        let calendar = Calendar(identifier: .gregorian)
        let weekdayNumber = calendar.component(.weekday, from: day)

        var templatesToRemove: [AppointmentTemplate] = []

        for template in appointmentDesciptions {
            let possibleDays = template.weekdays.isEmpty ? [2, 3, 4, 5, 6] : template.weekdays
            guard possibleDays.contains(weekdayNumber) else {
                continue
            }

            let rrule = template.rrule
            let isEventHappening = rrule != nil ? true : Double.random(in: 0..<1) < (template.probabilityOfTakingPlace ?? 1.0)
            guard isEventHappening else {
                continue
            }

            let time = template.typicalTimes.randomElement() ?? Time(hour: 9, minute: 0)
            guard let titleAndDescription = template.titlesAndDescriptions.randomElement() else { continue }
            var title = titleAndDescription.title
            var description = titleAndDescription.description
            let location = titleAndDescription.location
            let duration = titleAndDescription.durations.randomElement() ?? 30

            let startDate = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: day)!

            if rrule != nil {
                templatesToRemove.append(template)
            }

            let minGuests = titleAndDescription.minParticipants
            let maxGuests = titleAndDescription.maxParticipants

            var guests = [Person]()
            if (minGuests != nil) || (maxGuests != nil) {
                let range = (minGuests ?? 0)...(maxGuests ?? contacts.count)
                var allContacts = contacts
                for _ in range {
                    guard let guest = allContacts.randomElementByRemoving() else { break }
                    guests.append(guest)
                }

                if !guests.isEmpty {
                    let firstNames: [String] = guests.map( { $0.firstName ?? $0.displayName } ).sorted { $0 < $1 }
                    let listFormater = ListFormatter()
                    listFormater.locale = locale
                    let combinedNames = listFormater.string(from: firstNames)!
                    
                    title = title.replacingOccurrences(of: "{{NAME}}", with: combinedNames)
                    if description != nil {
                        description = description!.replacingOccurrences(of: "{{NAME}}", with: combinedNames)
                    }
                }
            }

            let request = AppointmentRequest.from(title: title, description: description, startDate: startDate, duration: duration, location: location, repeatRule: rrule, guests: guests)

            result.append(request)
        }

        appointmentDesciptions.removeAll(where: { templatesToRemove.contains($0) })

        return result
    }

}
