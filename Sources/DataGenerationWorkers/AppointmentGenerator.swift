import Foundation

class AppointmentGenerator {

    let startDate: Date
    let endDate: Date

    var appointmentDesciptions: [AppointmentTemplate]

    /// Returns a generator for the time frame -days from now until +days into the future
    static func generator(days: Int, appointmentDesciptions: [AppointmentTemplate]) -> AppointmentGenerator {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()

        let firstDay = calendar.date(byAdding: .day, value: -days, to: now)!
        let lastDay = calendar.date(byAdding: .day, value: days, to: now)!

        return AppointmentGenerator(startDate: firstDay, endDate: lastDay, appointmentDesciptions: appointmentDesciptions)
    }

    init(startDate: Date, endDate: Date, appointmentDesciptions: [AppointmentTemplate]) {
        self.startDate = startDate
        self.endDate = endDate
        self.appointmentDesciptions = appointmentDesciptions
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
            if !template.weekdays.isEmpty {
                guard template.weekdays.contains(weekdayNumber) else {
                    continue
                }
            }
            let rrule = template.rrule
            let isEventHappening = rrule != nil ? true : Double.random(in: 0..<1) < (template.probabilityOfTakingPlace ?? 1.0)
            guard isEventHappening else {
                continue
            }

            let time = template.typicalTimes.randomElement() ?? Time(hour: 9, minute: 0)
            guard let titleAndDescription = template.titlesAndDescriptions.randomElement() else { continue }
            let title = titleAndDescription.title
            let description = titleAndDescription.description
            let location = titleAndDescription.location
            let duration = titleAndDescription.durations.randomElement() ?? 30

            let startDate = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: day)!
            let request = AppointmentRequest.from(title: title, description: description, startDate: startDate, duration: duration, location: location, repeatRule: rrule)

            if rrule != nil {
                templatesToRemove.append(template)
            }

            result.append(request)
        }

        appointmentDesciptions.removeAll(where: { templatesToRemove.contains($0) })

        return result
    }

}
