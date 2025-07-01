import ArgumentParser
import EventKit
import Foundation

struct Agenda {
    private var eventStore = EKEventStore()

    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(macOS 14, *) {
            self.eventStore.requestFullAccessToEvents { granted, error in
                if let error {
                    print(error)
                    completion(false)
                    return
                }
                completion(granted)
            }
        } else {
            self.eventStore.requestAccess(to: .event) { granted, error in
                if let error {
                    print(error)
                    completion(false)
                    return
                }
                completion(granted)
            }
        }
    }

    func fetchEvents(startDate: Date, endDate: Date, calendarName: String?) -> [EKEvent] {
        var targetCalendars: [EKCalendar]? = nil
        if let name = calendarName {
            let allCalendars = self.eventStore.calendars(for: .event)
            targetCalendars = allCalendars.filter { $0.title.lowercased() == name.lowercased() }
        }

        let predicate = self.eventStore.predicateForEvents(
            withStart: startDate, end: endDate, calendars: targetCalendars)

        return self.eventStore.events(matching: predicate)
    }
}

enum AgendaError: Error {
    case AccessDenied
    case InvalidDateFormat
}

/// Supported meeting providers.
enum MeetingPlatform: String, CaseIterable {
    case zoom = "zoom"
    case googleMeet = "google"
    case microsoftTeams = "teams"
    case webex = "webex"

    /// Regex pattern that matches both full (`https://…`) and protocol‑less
    /// links for the provider.
    var regex: String {
        switch self {
        case .zoom:
            return "(?:https?://)?[\\w.-]*zoom\\.us/[\\w/?=&\\-]+"
        case .googleMeet:
            return "(?:https?://)?meet\\.google\\.com/[\\w-]+"
        case .microsoftTeams:
            return "(?:https?://)?teams\\.microsoft\\.com/l/meetup-join/[\\w%_.~=-]+"
        case .webex:
            return "(?:https?://)?[\\w.-]*webex\\.com/[\\w/?=&%\\-]+"
        }
    }
}

struct CodableEvent: Codable {
    let title: String?
    let startDate: Date?
    let endDate: Date?
    let location: String?
    let notes: String?
    let meetingURL: URL?

    init(from event: EKEvent) {
        self.title = event.title
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.location = event.location
        self.notes = event.notes
        self.meetingURL = event.meetingURL
    }
}

/// Stateless helper for extracting the first matching meeting URL
/// from any free‑form text (event notes, location, etc.).
struct MeetingURLExtractor {
    /// Returns the first meeting link found in the given calendar event.
    static func from(event: EKEvent) -> URL? {
        // Prefer the explicit “URL” field if it is already a meeting link.
        if let url = event.url, Self.isMeetingURL(url.absoluteString) {
            return url
        }
        // Fall back to notes & location.
        return Self.firstMeetingURL(
            in: [event.notes, event.location].compactMap { $0 }.joined(separator: " "))
    }

    /// Returns the first meeting link found inside the supplied text.
    static func firstMeetingURL(in text: String) -> URL? {
        for platform in MeetingPlatform.allCases {
            if let urlString = Self.firstMatch(of: platform.regex, in: text) {
                // Ensure we have a scheme
                let normalized =
                    urlString.hasPrefix("http")
                    ? urlString
                    : "https://\(urlString)"
                return URL(string: normalized)
            }
        }
        return nil
    }

    /// Boolean convenience
    static func isMeetingURL(_ urlString: String) -> Bool {
        MeetingPlatform.allCases.contains { urlString.lowercased().contains($0.rawValue) }
    }

    // MARK: - Regex little helper
    private static func firstMatch(of pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range),
            let range = Range(match.range, in: text)
        {
            return String(text[range])
        }
        return nil
    }
}

// Sugar‑coat EKEvent.
extension EKEvent {
    /// The first supported meeting URL contained in this event, if any.
    var meetingURL: URL? { MeetingURLExtractor.from(event: self) }
}

struct AgendaCommand: ParsableCommand {
    @Option(name: .long, help: "Filter events by calendar name")
    var calendar: String?

    @Flag(name: .long, help: "Print JSON in a human-readable format.")
    var pretty: Bool = false

    @Option(
        name: .long,
        help:
            "Date to fetch events for (e.g., 'today', 'tomorrow', 'yyyy-MM-dd'). Cannot be used with --start-date or --end-date."
    )
    var date: String?

    @Option(
        name: .long,
        help: "The start date for the event range (yyyy-MM-dd). Must be used with --end-date.")
    var startDate: String?

    @Option(
        name: .long,
        help: "The end date for the event range (yyyy-MM-dd). Must be used with --start-date.")
    var endDate: String?

    func run() throws {
        // Validate date options
        // Rule 1: Ensure --date and --start-date/--end-date are not used together.
        if date != nil && (startDate != nil || endDate != nil) {
            throw ValidationError("Cannot use --date with --start-date or --end-date.")
        }

        // Rule 2: Ensure --start-date and --end-date are used as a pair.
        if (startDate != nil && endDate == nil) || (startDate == nil && endDate != nil) {
            throw ValidationError("The --start-date and --end-date options must be used together.")
        }

        // Rule 3: Ensure at least one date-related option is provided.
        if date == nil && startDate == nil {
            throw ValidationError(
                "You must provide either --date or both --start-date and --end-date.")
        }

        let semaphore = DispatchSemaphore(value: 0)
        var accessGranted = false
        let agenda = Agenda()
        agenda.requestAccess { granted in
            accessGranted = granted
            semaphore.signal()
        }

        semaphore.wait()

        if !accessGranted {
            throw AgendaError.AccessDenied
        }

        let dateRange: (startDate: Date, endDate: Date)?

        if let dateString = date {
            dateRange = getDateRange(for: dateString)
        } else if let start = startDate, let end = endDate {
            dateRange = getDateRange(from: start, to: end)
        } else {
            throw ValidationError("Invalid date configuration.")
        }

        guard let (startDate, endDate) = dateRange else {
            throw AgendaError.InvalidDateFormat
        }

        let events = agenda.fetchEvents(
            startDate: startDate, endDate: endDate, calendarName: calendar)
        let codableEvents = events.map {
            CodableEvent(from: $0)
        }

        let encoder = JSONEncoder()
        if pretty {
            encoder.outputFormatting = .prettyPrinted
        }
        encoder.dateEncodingStrategy = .iso8601

        do {
            let jsonData = try encoder.encode(codableEvents)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
        } catch {
            throw error
        }

    }

    func getDateRange(for input: String) -> (startDate: Date, endDate: Date)? {
        let calendar = Calendar.current
        var baseDate: Date

        if input == "today" {
            baseDate = Date()
        } else if input == "tomorrow" {
            baseDate = calendar.date(byAdding: .day, value: 1, to: Date())!
        } else if let parsedDate = parseDate(from: input) {
            baseDate = parsedDate
        } else {
            return nil
        }
        let start = calendar.startOfDay(for: baseDate)
        let end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start)!
        return (start, end)
    }

    func getDateRange(from startString: String, to endString: String) -> (
        startDate: Date, endDate: Date
    )? {
        guard let startDate = parseDate(from: startString),
            let endDate = parseDate(from: endString)
        else {
            return nil
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        let endOfDay = calendar.date(
            byAdding: DateComponents(day: 1, second: -1), to: calendar.startOfDay(for: endDate))!

        return (startOfDay, endOfDay)
    }

    private func parseDate(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}

AgendaCommand.main()
