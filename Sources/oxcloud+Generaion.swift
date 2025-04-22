//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 17.04.25.
//

import ArgumentParser
import Foundation

extension OXCloud {

    struct Generate: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "generate", abstract: "Data generation operations.", subcommands: [GenerateAppointments.self])
    }

    struct GenerateAppointments: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "appointments", abstract: "Generate appointments", discussion: """
            Generate appointments. The `source` points to a file containing an **array** of JSON objects describing the appointments to be created.
            The description for one appointment looks like this:
            {
                "titlesAndDescriptions": [
                    {
                        "title": "Team Call",
                        "description": "Daily Team Call",
                        "location": "Zoom Room",
                        "durations": [30]
                    }
                ],
                "typicalTimes": [
                    {
                        "hour": 11,
                        "minute": 0
                    }
                ],
                "weekdays": [2, 3, 4, 5, 6],
                "probabilityOfTakingPlace": 0.5,
                "rrule": "FREQ=DAILY;INTERVAL=2"
            }
            `titlesAndDescriptions` contains an array of combinations of `title`, `description`, `location` and an array of `durations`. If more than one duration is given, one is chosen randomly. If none is given, 30 is used. One entry of `titlesAndDescriptions` is chosen randomly. Only the `title` is mandatory.
            `typicalTimes` contains typical starting times for that kind of appointment. If none is given, 9:00 is used.
            `weekdays` contains the weekdays the event can take place. 1 is Sunday. Hence, `[2, 3, 4, 5, 6]` would refer to "Monday to Friday". If no weekday is specified, the appointment is assumed to be able to take place at any day.
            `probabilityOfTakingPlace` refers to the chance of an event taking place. Values are in the range 0..1. If none is provided, 1 is assumed which means the appointment will take place.
            
            If an rrule is specified, the template is only used once for the first day for which appointments are being generated. If an rrule is provided, the `probabilityOfTakingPlace` is ignored should it be specified.
            
            Recurring and non recurring templates can be mixed in one array.
            
            For any array our of which an element is chosen randomly (like the duration or typical start times), odds of one entry to be chosen can be elevated by simply repeating it. [30, 30, 30, 60] for `duration` means a 25% chance of the appointment lasting 60 minutes and 75% of it lasting 30 minutes.
            """)

        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var pathOptions: ImportPathOptions
        @OptionGroup var appointmentGenerationOptions: GenerateAppointmentsOptions

        mutating func run() async throws {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: pathOptions.path))
                let jsonDecoder = JSONDecoder()
                let appointmentTemplates: [AppointmentTemplate] = try jsonDecoder.decode([AppointmentTemplate].self, from: data)

                let appointmentGenerator = AppointmentGenerator.generator(days: appointmentGenerationOptions.days, appointmentDesciptions: appointmentTemplates)
                let requests = appointmentGenerator.generateAppointments()
                print(requests)
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }
}
