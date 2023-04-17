//
//  AppDB.swift
//  Whisky
//
//  Created by Isaac Marovitz on 17/04/2023.
//

import Foundation
import Alamofire
import SwiftSoup

class AppDB {
    static func makeRequest(appName: String) async -> [Entry] {
        let appDBForm = AppDBForm(sappFamily_appNameData: appName)
        let encoder = URLEncodedFormEncoder(alphabetizeKeyValuePairs: false,
                                            boolEncoding: .literal,
                                            keyEncoding: .custom({ $0.replacingOccurrences(of: "_", with: "-") }))
        var entries: [Entry] = []

        do {
            // Should adjust URL params later
            // swiftlint:disable:next line_length
            let url = "https://appdb.winehq.org/objectManager.php?bIsQueue=false&bIsRejected=false&sClass=application&sTitle=Browse+Applications&iItemsPerPage=200&iPage=1&sOrderBy=appName&bAscending=true"
            let html = try await AF.request(url,
                                             method: .post,
                                             parameters: appDBForm,
                                             encoder: URLEncodedFormParameterEncoder(encoder: encoder))
                                   .serializingString().value

            let document = try SwiftSoup.parse(html)
            if let table = try document.select("tbody").first() {
                for row in try table.select("tr") {
                    let data = try row.select("td")
                    let entry = Entry(name: try data[0].text(),
                                      entry: Int(try data[1].text()) ?? 0,
                                      description: try data[2].text())
                    entries.append(entry)
                }
            }
        } catch {
            print(error)
        }

        return entries.sorted { $0.entry < $1.entry }
    }
}

struct Entry {
    let name: String
    let entry: Int
    let description: String
}

// swiftlint:disable identifier_name
struct AppDBForm: Encodable {
    let iappVersion_ratingOp: Int = 5
    let iappCategoryOp: Int = 11
    let iappVersion_licenseOp: Int = 5
    var sappVersion_ratingData: AppVersionRatingData = .empty
    var iversions_idOp: NumOp = .equalTo
    var sversions_idData: VersionsIdData = .empty
    var sappCategoryData: AppCategoryData = .empty
    var sappVersion_licenseData: AppVersionLicenseData = .empty
    var iappFamily_keywordsOp: StringOp = .contains
    var sappFamily_keywordsData: String = ""
    var iappFamily_appNameOp: StringOp = .contains
    var sappFamily_appNameData: String = ""
    let ionlyDownloadableOp: Int = 10
    var sonlyDownloadableData: Bool = false
    let iappFamily_appNameOp0: StringOp = .contains
    let sappFamily_appNameData0: String = ""
    var sFilterSubmit: String = ""
}
// swiftlint:enable identifier_name

enum AppVersionRatingData: String, Encodable {
    case empty = ""
    case platinum = "Platinum"
    case gold = "Gold"
    case silver = "Silver"
    case bronze = "Bronze"
    case garbage = "Garbage"
}

enum NumOp: Int, Encodable {
    case equalTo = 5
    case lessThan = 7
    case greaterThan = 6
}

enum StringOp: Int, Encodable {
    case contains = 2
    case startsWith = 3
    case endsWith = 4
}

enum VersionsIdData: String, Encodable {
    case empty = ""
    case wine86 = "882"
    case wine85 = "880"
    case wine702 = "878"
    case wine84 = "875"
    case wine83 = "873"
    case wine82 = "871"
    case wine81 = "869"
    case wine80 = "867"
    case wine8rc5 = "865"
    case wine8rc4 = "861"
}

enum AppCategoryData: String, Encodable {
    case empty = ""
    case educationalCBT = "82"
    case games = "2"
    case fps = "16"
    case stealth = "146"
    case tps = "139"
    case action = "84"
    case platformer = "147"
    case adventure = "69"
    case adult = "134"
    case atmospheric = "137"
    case cardPuzzleBoard = "78"
    case educationalChildren = "76"
    case emulators = "65"
    case exploration = "136"
    case funStuff = "112"
    case gameTools = "97"
    case horror = "135"
    case scifi = "145"
    case mystery = "140"
    case mmorpg = "103"
    case openWorld = "138"
    case pointAndClick = "144"
    case puzzle = "143"
    case rpg = "55"
    case simulation = "88"
    case adultSim = "132"
    case citySim = "128"
    case vehicleSim = "124"
    case tycoon = "129"
    case sports = "86"
    case strategy = "57"
    case rts = "126"
    case rtt = "127"
    case turnBased = "130"
    case survival = "141"
    case walkingSim = "142"
    case multimedia = "29"
    case audio = "1"
    case audioPlayers = "14"
    case soundEditing = "13"
    case graphics = "3"
    case rendering = "21"
    case graphicsDemos = "95"
    case graphicsEditing = "19"
    case graphicsViewer = "18"
    case screensavers = "101"
    case video = "31"
    case networking = "5"
    case browsers = "33"
    case chatIm = "37"
    case email = "35"
    case fileTransfer = "74"
    case hamRadio = "125"
    case maps = "117"
    case netTools = "45"
    case remoteAccess = "90"
    case productivity = "4"
    case database = "25"
    case desktopPublishing = "92"
    case finance = "63"
    case legal = "107"
    case officeSuites = "43"
    case officeUtilities = "61"
    case presentation = "26"
    case spreadsheet = "24"
    case textEditors = "53"
    case webDesign = "27"
    case wordProcessing = "23"
    case programming = "6"
    case documentation = "47"
    case benchmark = "121"
    case dictionary = "120"
    case encylopedia = "122"
    case genalogy = "118"
    case religious = "119"
    case scientific = "8"
    case astronomy = "99"
    case biology = "110"
    case cad = "59"
    case chemistry = "116"
    case eda = "49"
    case flowchart = "71"
    case math = "51"
    case specialPurpose = "105"
    case utilities = "7"
    case antivirus = "133"
    case compression = "11"
    case fileSystem = "10"
}

enum AppVersionLicenseData: String, Encodable {
    case empty = ""
    case retail = "Retail"
    case subscription = "Subscription"
    case free = "Free to use"
    case freeToShare = "Free to use and share"
    case demo = "Demo"
    case shareware = "Shareware"
}
