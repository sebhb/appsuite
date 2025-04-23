import Foundation

struct Time: Decodable, Equatable {
    let hour: Int
    let minute: Int

    static func == (lhs: Time, rhs: Time) -> Bool {
        return lhs.hour == rhs.hour && lhs.minute == rhs.minute
    }
}

struct TitleDescriptionLocation: Decodable, Equatable {
    let title: String
    let description: String?
    let location: String?
    /// One of these will be chosen by random. In order to increase the probability of a duration being chosen, add it more than once, e.g. [30, 30, 30, 60] gives a 75% chance of a duration 0f 30 minutes and a 25% chance of a duration of 60 minutes.
    /// Supply only one value to use a fixed value in any case.
    let durations: [Int]

    static func == (lhs: TitleDescriptionLocation, rhs: TitleDescriptionLocation) -> Bool {
        return lhs.title == rhs.title
        && lhs.description == rhs.description
        && lhs.location == rhs.location
        && lhs.durations == rhs.durations
    }
}

struct AppointmentTemplate: Decodable, Equatable {
    let titlesAndDescriptions: [TitleDescriptionLocation]
    let typicalTimes: [Time]
    let weekdays: [Int]
    let probabilityOfTakingPlace: Double?
    let rrule: String?

    static func == (lhs: AppointmentTemplate, rhs: AppointmentTemplate) -> Bool {
        return lhs.titlesAndDescriptions == rhs.titlesAndDescriptions
        && lhs.typicalTimes == rhs.typicalTimes
        && lhs.weekdays == rhs.weekdays
        && lhs.probabilityOfTakingPlace == rhs.probabilityOfTakingPlace
        && lhs.rrule == rhs.rrule
    }
}
