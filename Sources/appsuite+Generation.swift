import ArgumentParser
import Foundation

extension Appsuite {

    struct Generate: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "generate", abstract: "Data generation operations.", subcommands: [GenerateAppointments.self, GenerateContacts.self])
    }

    struct GenerateAppointments: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "appointments", abstract: "Generate appointments", discussion: """
            Generate appointments. The `source` points to a file containing an ARRAY of JSON objects describing the appointments to be created.
            The description for one appointment looks like this:
            {
                "titlesAndDescriptions": [
                    {
                        "title": "Team Call",
                        "description": "Daily Team Call",
                        "location": "Zoom Room",
                        "durations": [30],
                        "minParticipants": 1,
                        "maxParticipants": 3
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
            `titlesAndDescriptions` contains an array of combinations of `title`, `description`, `location` and an array of `durations`. If more than one duration is given, one is chosen randomly. If none is given, 30 is used. One entry of `titlesAndDescriptions` is chosen randomly. Only the `title` is mandatory. If either `minParticipants` and/or `maxParticipants` is specified, random contacts from the user's address book will be added as guests to the event. Any occurrence of {{NAME}} in either the title or the description will be replaced with a list of the names of the guests selected. Use the command line parameter `locale` to specify the locale to use for the creation of the list. (This has an influence on commas and whether and how a last name is added with e.g. an "and"). A description could contain the text "Discuss upcoming project with {{NAME}}.", that would lead to the names of the randomly selected partipicants to be added. If none of the two values `minParticipants` and `maxParticipants` is specified, no guests are added to the appointment.
            NOTE: While the events are created in a manner that no emails are sent to external parties, manual removal of these events DOES trigger a real email to be sent. Either make sure to use non-existant email domains or use the API to delete these events in a manner that does not trigger the sending of emails or use the `delete appointments` subcommand which deletes appointments without sending notifications to participants.
            `typicalTimes` contains typical starting times for that kind of appointment. If none is given, 9:00 is used.
            `weekdays` contains the weekdays the event can take place. 1 is Sunday. Hence, `[2, 3, 4, 5, 6]` would refer to "Monday to Friday". If no weekday is specified, the appointment is assumed to be able to take place at any workday (Monday to Friday) but not on weekends.
            `probabilityOfTakingPlace` refers to the chance of an event taking place. Values are in the range 0..1. If none is provided, 1 is assumed which means the appointment will take place.
            
            If an rrule is specified, the template is only used once for the first day for which appointments are being generated. If an rrule is provided, the `probabilityOfTakingPlace` is ignored should it be specified.
            
            Recurring and non recurring templates can be mixed in one array.
            
            For any array out of which an element is chosen randomly (like the duration or typical start times), odds of one entry to be chosen can be elevated by simply repeating it. [30, 30, 30, 60] for `duration` means a 25% chance of the appointment lasting 60 minutes and 75% of it lasting 30 minutes.
            """)

        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var pathOptions: ImportPathOptions
        @OptionGroup var appointmentGenerationOptions: GenerateAppointmentsOptions

        mutating func run() async throws {
            do {
                let getContactsWorker = GetContactsWorker(userCredentialsOptions: userCredentialsOptions)
                let contacts = try await getContactsWorker.getContacts()

                let data = try Data(contentsOf: URL(fileURLWithPath: pathOptions.path))
                let jsonDecoder = JSONDecoder()
                let appointmentTemplates: [AppointmentTemplate] = try jsonDecoder.decode([AppointmentTemplate].self, from: data)

                let locale = Locale(identifier: appointmentGenerationOptions.locale)

                let appointmentGenerator = AppointmentGenerator.generator(days: appointmentGenerationOptions.days, appointmentDesciptions: appointmentTemplates, contacts: contacts, locale: locale)
                let requests = appointmentGenerator.generateAppointments()

                let appointmentCreationWorker = AppointmentCreationWorker(userCredentialsOptions: userCredentialsOptions)
                try await appointmentCreationWorker.createAppointments(appointmentRequests: requests)
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

    struct GenerateContacts: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "contacts", abstract: "Generate contacts", discussion: """
            Generate Contacts. The `source` points to a file containing an ARRAY of JSON objects describing the contacts to be created.
            The description for one contact looks like this:
            {
                "firstNames": [
                    "James",
                    "John"
                ],
                "lastNames": [
                    "Smith",
                    "Johnson"
                ],
                "addresses": [
                    {
                        "street": "1 Main Street",
                        "city": "South Portland",
                        "state": "ME",
                        "zip": "04062",
                        "country": "USA"
                    },
                    {
                        "street": "425 Elmwood Ave",
                        "city": "Buffalo",
                        "state": "NY",
                        "zip": "14222",
                        "country": "USA"
                    }
                ],
                "emailDomains": [
                    "yahoo.com",
                    "gmail.com",
                    "icloud.com"
                ],
                "probabilityOfAddress": 0.75,
                "probabilityOfEmail": 0.75,
                "avatarsPath": "Male Avatars"
            }
            
            `firstNames` and `lastNames` contain names that are randomly combined with each other.
            `probabilityOfAddress` expresses the probability with which a new contact will have a postal address. `probabilityOfEmail` expresses that probability of having an email address, respectively.
            
            A postal address is randomly taken from the `addresses` array. An address is only used once. So, make sure to provide enough addresses for all contacts that are to be generated.
            Email addresses are randomly generated by using one of the domains from `emailDomains`.
            
            Lastly, all avatars from `avatarsPath` will be used for contacts until they have been used up.

            Only `firstNames` and `lastNames` are required values. Everything else is optional. The default values for `probabilityOfAddress` and `probabilityOfEmail` is 1.
            For addresses, `street`, `city`, and `zip` are required values.
            
            `avatarsPath` is the relative path (from source) to a directory with avatars. Supported formats are JPG and PNG.
            Also note that only "simple" path operations are supported. Referencing a subdirectory (e.g. "avatars/marketing/") does work but traversing the hierarchy up using ".." is not supported. "~" is not evaluated, either.
            If a subdirectory is referenced, the platform's path separator has to be used.
            
            If the JSON contains more than one template in the form above, one is chosen at random for every person to be generated.
            """)

        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var pathOptions: ImportPathOptions
        @OptionGroup var contactGenerationOptions: GenerateContactsOptions

        mutating func run() async throws {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: pathOptions.path))
                let jsonDecoder = JSONDecoder()
                let contactTemplates: [ContactTemplate] = try jsonDecoder.decode([ContactTemplate].self, from: data)

                let contactsGenerator = ContactGenerator(numberOfContacts: contactGenerationOptions.numberOfContacts, contactTemplates: contactTemplates, basePath: pathOptions.path.removingLastPathComponent())
                let requests = contactsGenerator.generateContacts()

                let personCreationWorker = PersonCreationWorker(userCredentialsOptions: userCredentialsOptions)
                try await personCreationWorker.createPersons(requests)
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }
}
