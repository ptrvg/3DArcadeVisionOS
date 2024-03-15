//
//  HomeModel.swift
//  HomeWatch
//
//  Created by Peter Vogels on 06/03/2022.
//

import Foundation
import HomeKit
import UIKit
import SwiftUI // TODO Reove when color bug is fixed



struct HKHome: Identifiable, Equatable, Codable {
    
    var resizeToggle = false
    
    // Display
    var id = UUID()
    var name = "" // TODO: Name in homekit. Not changed in this app.
    var caption = "" // Home name as displayed in this app
    var atHomeIcon = Icon(name: "house.fill", color: .customSecondary, caption: "", type: .symbol)
    var awayHomeIcon = Icon(name: "house", color: .customSecondary, caption: "", type: .symbol)
    var theme: Theme = Theme() // UI Specific I dont want it here...
    var info: String = "https://home-watch.nl/app/use/home_view_usage.html"
    
    var rooms: [HKRoom] = []
    var selectedRoom = HKRoom(name: "None") // TODO: Not here!
    
    var cameras: [HKAccessory]? = []
    
    // Status
    var homeStatusColor: Color?
    var atHomeStatus = true
    // TODO: Create a Weather struct/class ? Or make this generic?
    var temperature = ""
    var windSpeed = ""
    var humidity = ""
    var carbonDioxideLevel = ""
    var weatherIcon = "sparkles"
    var weatherIconTintColor = UIColor.lightGray
    var rain: Bool = false
    var rainData = ""

    
#if targetEnvironment(macCatalyst)
    // MenuBar Status Items
    var menuBarStatusItemsCharacteristics: [HKCharacteristic]?
#endif
    //var homeStatusHistoryCharts: HomeStatus?
    
    mutating func updateHomeStatusColor() -> Void {
        let colors = rooms.compactMap { $0.statusColor }
        var color = Color.green
        if colors.contains(Color.red) {
            color = Color.red
        }
        else if colors.contains(Color.yellow) {
            color = Color.yellow
        }
        else if colors.contains(Color.orange) {
            color = Color.orange
        }
        else if colors.contains(Color.cyan) {
            color = Color.cyan
        }
        homeStatusColor = color
    }
    
//    static func == (lhs: HKHome, rhs:HKHome) -> Bool {
//        return lhs.id == rhs.id
//    }
}

// Load and Save HKHome
extension HKHome {
    enum CodingKeys: CodingKey {
        case id
        case name
        case caption
        case atHomeIcon
        case awayHomeIcon
        case theme
        case info
        case rooms
        case selectedRoom
#if targetEnvironment(macCatalyst)
        case menuBarStatusItemsCharacteristics
#endif
      //  case homeStatusHistoryCharts
    }
    
    // Add a new property then use do an catch
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        caption = try container.decode(String.self, forKey: .caption)
        atHomeIcon = try container.decode(Icon.self, forKey: .atHomeIcon)
        awayHomeIcon = try container.decode(Icon.self, forKey: .awayHomeIcon)
        theme = try container.decode(Theme.self, forKey: .theme)
        info = try container.decode(String.self, forKey: .info)
        rooms = try container.decode([HKRoom].self, forKey: .rooms)
        selectedRoom = try container.decode(HKRoom.self, forKey: .selectedRoom)
#if targetEnvironment(macCatalyst)
        menuBarStatusItemsCharacteristics = try? container.decode([HKCharacteristic].self, forKey: .menuBarStatusItemsCharacteristics)
#endif
      //  homeStatusHistoryCharts = try? container.decode(HomeStatus.self, forKey: .homeStatusHistoryCharts)
    }
}

// Convenience Functions
extension HKHome {
    // Get all accessories from rooms
    func getAllAccessories() -> [HKAccessory] {
        var accessories: [HKAccessory]  = []
        for room in rooms {
            accessories = accessories + room.accessories
        }
        return accessories
    }
    
    func getAllAccessoriesCompatibleWithStatusUpdates() -> [HKAccessory] {
        let accessories: [HKAccessory]  = getAllAccessories()
        var filteredAccessories: [HKAccessory]  = []
        for accessory in accessories {
            guard let services = accessory.accessory?.services else {continue}
            let chars = services.flatMap { $0.characteristics }
                .filter { $0.characteristicType == HMCharacteristicTypePowerState || $0.characteristicType == HMCharacteristicTypeContactState || $0.characteristicType == HMCharacteristicTypeCurrentHeatingCooling || $0.characteristicType == HMCharacteristicTypeStatusActive }
            if chars.count > 0 {
                filteredAccessories.append(accessory)
            }
        }
        return filteredAccessories
    }

    func getAllcharacteristiscs() -> [HKCharacteristic] {
        var characteristics: [HKCharacteristic] = []
        for room in rooms {
            characteristics = characteristics + room.characteristics
        }
        return characteristics
    }
    
    func getAllcharacteristiscsOfType(types: [String]) -> [HKCharacteristic] {
        var characteristics: [HKCharacteristic] = []
        guard types.count > 0 else {return []}
        for room in rooms {
            characteristics = characteristics + room.getAllcharacteristiscsOfType(types: types)
        }
        return characteristics
    }
    
    // Get all scenes from rooms
    func getAllScenes() -> [HKScene] {
        var scenes: [HKScene] = []
        for room in rooms {
            scenes = scenes + room.scenes
        }
        scenes = Array(Set(scenes)).sorted {$0.name.lowercased() < $1.name.lowercased()}
        return scenes
    }
}

struct HKRoom: Identifiable, Equatable, Codable {
    // Display
    var id = UUID()
    var name = "" // TODO: Name in homekit. Not changed in this app. So change to let
    var caption = "" // Room name as displayed in this app
    var icon: Icon = Icon(name: "rectangle", color: .customSecondary, caption: "", type: .symbol)
    var theme: Theme = Theme() // UI Specific I dont want it here...
    var info: String = "https://home-watch.nl/app/use/room_view_usage.html"
    
    // Status TODO: Maybe add seperate properties to calculate states from room accessories. Now if the user selects those he wants to use for status updates. The discarded are no longer available in this room. But we should be able to get it from the default home...
    //
    var doorOpen = false
    var windowOpen = false
    var lightsOn = false
    var heating = false
    
    var currentTemperature: HKCharacteristic?
    var targetTemperature: HKCharacteristic?
    // TODO: 3 below are not used
    var humidityLevel: HKCharacteristic?
    var carbonDioxideLevel: HKCharacteristic?
    var airQuality: HKCharacteristic?
    
    var lights: [HKAccessory] = []
    var thermoststats: [HKAccessory] = []
    var cameras: [HKAccessory] = []
    var others: [HKAccessory] = []
    
    var statusColor: Color? = .gray
    // Accessories considered for room status updates TODO: rename to statusLights
    var statusLights: [HKAccessory] = []
    var statusThermoststats: [HKAccessory] = []
    var statusWindows: [HKAccessory] = []
    var statusDoors: [HKAccessory] = []

    
    var accessories: [HKAccessory] = []
    var characteristics: [HKCharacteristic] = []
    var scenes: [HKScene] = []
    
    var occupancy = false
    var errorLoadingRoomData = true
    // Advanced none homekit accessories
    var tadoID = "1"
    var awair = ""
    var updateAccessoriesFinished: Bool? {
        didSet {
            if updateAccessoriesFinished == true {
                
            }
        }
    }
    var nestedCharacteristics: [[HKCharacteristic]] = []
    var update: Bool?
    
   
    
//    mutating func updateAccessoriesStatus() -> Void {
//    }
    
    mutating func updateRoomStatus() -> Void {
        var color = Color.green
        if doorOpen {
            color = Color.red
        }
        else if windowOpen {
            color = Color.yellow
        }
        else if heating {
            color = Color.orange
        }
        else if lightsOn {
            color = Color.cyan
        }
        statusColor = color
        //nestedCharacteristics = getNestedCharacteristics()
    }
    
//    static func == (lhs: HKRoom, rhs:HKRoom) -> Bool {
//        return lhs.id == rhs.id && lhs.imageName == rhs.imageName
//    }
}

// Update, Load and Save HKRoom
extension HKRoom {
    mutating func updateRoomfromID() -> Void {
        // TODO: Only checks for the correct it now...remove?
        if HomekitStore.shared.home.rooms.first(where: {$0.id == id}) == nil {
            print ("HKS A room not found \(name)")
            if  let _room = HomekitStore.shared.home.rooms.first(where: {$0.name == name}) {
                id = _room.id
                print ("HKS matched room by name \(name)")
                
                // TODO: NB Save the new id?
            } else {
                print ("HKS B room not found \(name)")
            }
        }
    }
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case caption
        case icon
        case theme
        case info
        case accessories
        case characteristics
        case scenes
        case currentTemperature
        case targetTemperature
        case humidityLevel
        case carbonDioxideLevel
        case airQuality
        case lights
        case thermoststats
        case cameras
        case others
        case statusLights
        case statusThermoststats
        case statusWindows
        case statusDoors
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        caption = try container.decode(String.self, forKey: .caption)
        icon = try container.decode(Icon.self, forKey: .icon)
        theme = try container.decode(Theme.self, forKey: .theme)
        info = try container.decode(String.self, forKey: .info)
        accessories = try container.decode([HKAccessory].self, forKey: .accessories)
        characteristics = try container.decode([HKCharacteristic].self, forKey: .characteristics)
        scenes = try container.decode([HKScene].self, forKey: .scenes)
        currentTemperature = try? container.decode(HKCharacteristic.self, forKey: .currentTemperature)
        targetTemperature = try? container.decode(HKCharacteristic.self, forKey: .targetTemperature)
        humidityLevel = try? container.decode(HKCharacteristic.self, forKey: .humidityLevel)
        carbonDioxideLevel = try? container.decode(HKCharacteristic.self, forKey: .carbonDioxideLevel)
        airQuality = try? container.decode(HKCharacteristic.self, forKey: .airQuality)
        statusLights = try container.decode([HKAccessory].self, forKey: .statusLights)
        statusThermoststats = try container.decode([HKAccessory].self, forKey: .statusThermoststats)
        statusWindows = try container.decode([HKAccessory].self, forKey: .statusWindows)
        statusDoors = try container.decode([HKAccessory].self, forKey: .statusDoors)
        cameras = try container.decode([HKAccessory].self, forKey: .cameras)
        lights = try container.decode([HKAccessory].self, forKey: .lights)
        thermoststats = try container.decode([HKAccessory].self, forKey: .thermoststats)
        others = try container.decode([HKAccessory].self, forKey: .others)
    }
}

// Convenience Functions
extension HKRoom {
    func getHomekitStoreRoom() -> HKRoom? {
        if let roomByID = HomekitStore.shared.home.rooms.first(where: {$0.id == id}) {
            return roomByID
        }
        // TODO: Remove?
        if  let roomByName = HomekitStore.shared.home.rooms.first(where: {$0.name == name}) {
            return roomByName
        }
        return nil
    }
    
    func getAllaccessoriesOfType(types: [String]) -> [HKAccessory] {
        var accessories: [HKAccessory] = []
        guard types.count > 0 else {return []}
        for type in types {
            accessories = accessories + self.accessories.filter {$0.accessoryType == type}
        }
        return accessories
    }
    
    func getAllcharacteristiscsOfType(types: [String]) -> [HKCharacteristic] {
        var characteristics: [HKCharacteristic] = []
        guard types.count > 0 else {return []}
        for type in types {
            characteristics = characteristics + (self.characteristics.filter {$0.characteristicType == type})
        }
        return characteristics
    }
    
    func getAllcharacteristiscsForAccessoriesWithState() -> [HMCharacteristic] {
        var characteristics: [HMCharacteristic]  = []
        let accessories = lights + cameras + thermoststats + others
        for accessory in accessories {
            var accessory = accessory
            let chars = accessory.getCharacteristicsForAccessoryState() + accessory.getCharacteristicsForAccessoryPowersStateAndThermostat()
            characteristics = characteristics + chars
        }
        return characteristics
    }
    
   mutating func updateAcessoriesWithState() {
       for (index, _) in lights.enumerated() {
           lights[index].update?.toggle()
        }
       for (index, _) in cameras.enumerated() {
           cameras[index].update?.toggle()
        }
       for (index, _) in thermoststats.enumerated() {
           thermoststats[index].update?.toggle()
        }
       for (index, _) in thermoststats.enumerated() {
           thermoststats[index].update?.toggle()
        }
       update?.toggle()
    }
    
    
    func getAllcharacteristiscsForScenes() -> [HMCharacteristic] {
        var characteristics: [HMCharacteristic]  = []
        for scene in scenes{
            if let a = scene.scene?.actions {
                for action in a {
                    if let _action = action as? HMCharacteristicWriteAction<NSCopying> {
                        characteristics.append(_action.characteristic)
                    }
                }
            }
        }
        return characteristics
    }
    
    mutating func updateScenesState() {
        for (index, _) in scenes.enumerated() {
             scenes[index].update?.toggle()
         }
     }
    
    func getCharacteristicFromCharacteristics(id: UUID) -> HKCharacteristic? {
        return characteristics.first(where: {$0.id == id})
    }
    
    // TODO: NB When the app starts this is called multiple times for each room. Optimize this
    func getNestedCharacteristics() -> [[HKCharacteristic]] {
        print ("DBPV room \(name)")
        var nestedCharacteristics: [[HKCharacteristic]] = []
        var chars = self.characteristics.unique{$0.id}

        for (index, _) in chars.enumerated() {
                chars[index].icon.color =  Color.customPrimary
                let caption = chars[index].icon.caption + " " + (chars[index].getStringForValue() ?? "")
                chars[index].icon.caption = caption
                chars[index].caption = caption
                chars[index].icon.captionColor =  Color.customPrimary
            chars[index].icon.captionLocation = .left
            
        }
        let remainder = chars.count % 3
        if remainder > 0 {
            let dummy = HKCharacteristic(id: UUID(), name: "HWDummy",caption: "", icon: Icon(name: "circle", color: Color.clear, caption: "", captionColor: .white, captionLocation: .left, type: .symbol))
            let dummyCount = 3 - remainder
            for _ in 0..<dummyCount {
                chars.append(dummy)
            }
        }
        for index in stride(from: 0, to: chars.count-1, by: 3) {
            var characteristics: [HKCharacteristic] = []
            characteristics.append(chars[index])
            characteristics.append(chars[index + 1])
            characteristics.append(chars[index + 2])
            nestedCharacteristics.append(characteristics)
        }
        return nestedCharacteristics
    }
    
    mutating func updateNestedCharacteristiscs(characteristic: HMCharacteristic) {
        for (index, boe) in nestedCharacteristics.enumerated() {
            for (index2, _) in boe.enumerated() {
                if nestedCharacteristics[index][index2].id == characteristic.uniqueIdentifier {
                    nestedCharacteristics[index][index2].value = nestedCharacteristics[index][index2].value
                    nestedCharacteristics[index][index2].icon.caption = self.characteristics.first(where: {$0.id == nestedCharacteristics[index][index2].id})?.icon.caption ?? ""
                    let caption =  nestedCharacteristics[index][index2].icon.caption + "  " + (nestedCharacteristics[index][index2].getStringForValue() ?? "")
                        nestedCharacteristics[index][index2].icon.caption = caption
                    nestedCharacteristics[index][index2].caption = caption
                    print ("hsm q x nested update \( nestedCharacteristics[index][index2].name) with value \( nestedCharacteristics[index][index2].value) source caption \(caption) hmchar \(nestedCharacteristics[index][index2].characteristic?.localizedDescription)")
                }
            }
        }
    }
    
    mutating func updateAllNestedCharacteristiscs() {
        for (index, item) in self.nestedCharacteristics.enumerated() {
            for (index2, _) in item.enumerated() {
                if nestedCharacteristics[index][index2].name != "HWDummy" {
                    nestedCharacteristics[index][index2].value = nestedCharacteristics[index][index2].value
                    nestedCharacteristics[index][index2].icon.caption = self.characteristics.first(where: {$0.id == nestedCharacteristics[index][index2].id})?.icon.caption ?? ""
                    let caption =  nestedCharacteristics[index][index2].icon.caption + " " + (nestedCharacteristics[index][index2].getStringForValue() ?? "")
                    nestedCharacteristics[index][index2].icon.caption =  caption
                    nestedCharacteristics[index][index2].caption = caption
                }
            }
        }
    }
    
}


// Setup Functions
extension HKRoom {
    func resetSetupRoom(room: HKRoom) -> HKRoom? {
       if var updatedRoom = resetRoom(room: room, personal: HWS.personal) {
           updatedRoom.characteristics = resetCharacteristic(room: updatedRoom, personal: HWS.personal)
           updatedRoom.accessories = []
           if !HWS.personal {
               for (index2, _) in updatedRoom.scenes.enumerated() {
                   if updatedRoom.scenes[index2].icon.caption == "" {
                       var title = updatedRoom.scenes[index2].name
                       if title.count > 30 {
                           title = String(title.prefix(28)) + ".."
                       }
                       updatedRoom.scenes[index2].icon.caption = title
                       updatedRoom.scenes[index2].icon.captionColor = .customPrimary
                   }
               }
           }
           return resetAccessories(room: updatedRoom)
       }
       return nil
   }
   
   func resetRoom(room: HKRoom, personal: Bool = false) -> HKRoom? {
       if room.name.lowercased().contains("woonkamer") {
           var woonkamer = room
           if let status = (HomekitStore.shared.home.getAllAccessories().filter{$0.name.lowercased() == "woonkamer licht status switch"}).first {
               woonkamer.statusLights = [status]
           }
           if let thermostat =  woonkamer.statusThermoststats.first {
               woonkamer.statusThermoststats = [thermostat]
           }
           woonkamer.scenes = woonkamer.scenes.filter{!$0.name.lowercased().contains("status") && !($0.name == "Koken") && !($0.name == "Uit Licht Grok en Go") && !($0.name == "Woonkamer Bollen Rood")}
           if woonkamer.scenes.count > 0 {
               let cameraOn = woonkamer.scenes.remove(at: woonkamer.scenes.count - 2)
               let cameraOff = woonkamer.scenes.remove(at: woonkamer.scenes.count - 1)
               let lightsOff = woonkamer.scenes.remove(at: 3)
               let lightsStandard = woonkamer.scenes.remove(at: 2)
               let lightsRelax = woonkamer.scenes.remove(at: 1)
               let spot = woonkamer.scenes.remove(at: 0)
               woonkamer.scenes.append(cameraOff)
               woonkamer.scenes.append(cameraOn)
               woonkamer.scenes.append(lightsOff)
               woonkamer.scenes.append(lightsRelax)
               woonkamer.scenes.append(lightsStandard)
               if let grok = HomekitStore.shared.home.getAllScenes().filter({$0.name.lowercased() == "animatie switch default aan"}).first {
                   woonkamer.scenes.append(grok)
               }
               woonkamer.scenes.append(spot)
           }
           return woonkamer
           //let complication = HWComplication(id: woonkamer.id , name: woonkamer.name, icon: woonkamer.icon, complicationType: .room)
           //HWS.userComplications.append(complication)
       }
       if room.name.lowercased().contains("gang") {
           var gang = room
           if let status = (HomekitStore.shared.home.getAllAccessories().filter{$0.name.lowercased() == "gang licht status switch"}).first {
               gang.statusLights = [status]
           }
           gang.scenes = gang.scenes.filter{!$0.name.lowercased().contains("status")}
           if gang.scenes.count > 2 {
               let element = gang.scenes.remove(at: 2)
               gang.scenes.insert(element, at: 0)
               
           }
           return gang
           //let complication = HWComplication(id: gang.id , name: gang.name, icon: gang.icon, complicationType: .room)
           //HWS.userComplications.append(complication)
       }
       if room.name.lowercased().contains("slaapkamer") {
           var slaapkamer = room
           if let status = (HomekitStore.shared.home.getAllAccessories().filter{$0.name.lowercased() == "slaapkamer licht status switch"}).first {
               slaapkamer.statusLights = [status]
           }
           slaapkamer.scenes = slaapkamer.scenes.filter{!$0.name.lowercased().contains("status")}
           if slaapkamer.scenes.count > 2 {
               var element = slaapkamer.scenes.remove(at: 2)
               slaapkamer.scenes.append(element)
               element = slaapkamer.scenes.remove(at: 1)
               slaapkamer.scenes.append(element)
               element = slaapkamer.scenes.remove(at: 0)
               slaapkamer.scenes.append(element)
           }
           return slaapkamer
       }
       if room.name.lowercased().contains("zolder") {
           var zolder = room
           if let status = (HomekitStore.shared.home.getAllAccessories().filter{$0.name.lowercased() == "zolder licht status switch"}).first {
               zolder.statusLights = [status]
           }
           if let thermostat =  zolder.statusThermoststats.first {
               zolder.statusThermoststats = [thermostat]
           }
           zolder.scenes = zolder.scenes.filter{!$0.name.lowercased().contains("status")}
           if let openWindow = HomekitStore.shared.home.getAllScenes().filter({$0.name.lowercased() == "zolder raam dicht"}).first {
               zolder.scenes.append(openWindow)
           }
           if let closeWindow = HomekitStore.shared.home.getAllScenes().filter({$0.name.lowercased() == "zolder raam open"}).first {
               zolder.scenes.append(closeWindow)
           }
           if zolder.scenes.count > 4 {
               let element = zolder.scenes.remove(at: 4)
               zolder.scenes.insert(element, at: 3)
               
           }
           return zolder
           //let complication = HWComplication(id: zolder.id , name: zolder.name, icon: zolder.icon, complicationType: .room)
           //HWS.userComplications.append(complication)
       }
       if room.name.lowercased().contains("vigo") {
           var vigo = room
           if let status = (HomekitStore.shared.home.getAllAccessories().filter{$0.name.lowercased() == "vigo licht status switch"}).first {
               vigo.statusLights = [status]
           }
           vigo.scenes = vigo.scenes.filter{!$0.name.lowercased().contains("status")}
           if vigo.scenes.count > 1 {
               var element = vigo.scenes.remove(at: 0)
               vigo.scenes.append(element)
               element = vigo.scenes.remove(at: 0)
               vigo.scenes.append(element)
           }
           return vigo
       }
       if room.name.lowercased().contains("badkamer") {
       var badkamer = room
          return badkamer
       }
       return personal ? nil : room
   }
   
   func resetCharacteristic(room: HKRoom, personal: Bool = false) -> [HKCharacteristic] {
       var characteristics: [HKCharacteristic] = []
       if let currentTemperature =
           (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeCurrentTemperature}.first) {
           characteristics.append(currentTemperature)
       }
       if let targetTemperature = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeTargetTemperature}.first) {
           characteristics.append(targetTemperature)
       }
       if let humidity = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeCurrentRelativeHumidity}.first) {
           characteristics.append(humidity)
       }
       if let climate = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeAirQuality}.first) {
           characteristics.append(climate)
       }
       if let co2 =
           (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeCarbonDioxideLevel}.first) {
           characteristics.append(co2)
       }
       if let co = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeCarbonMonoxideLevel}.first) {
           characteristics.append(co)
       }
       if let chemicals = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeVolatileOrganicCompoundDensity}.first) {
           characteristics.append(chemicals)
       }
       if let item = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeAirParticulateDensity}.first) {
           characteristics.append(item)
       }
       if let item = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeNitrogenDioxideDensity}.first) {
           characteristics.append(item)
       }
       if let item = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeOzoneDensity}.first) {
           characteristics.append(item)
       }
       if let item = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeSulphurDioxideDensity}.first) {
           characteristics.append(item)
       }
       if var item = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeCarbonMonoxideDetected}.first) {
           item.icon.caption = "CO"
           characteristics.append(item)
       }
       if var item = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeCarbonDioxideDetected}.first) {
           item.icon.caption = "CO2"
           characteristics.append(item)
       }
       if var item = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeLeakDetected}.first) {
           item.icon.caption = "Water Leak"
           characteristics.append(item)
       }
       
       if var item = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeMotionDetected}.first) {
           item.icon.caption = "Motion"
           characteristics.append(item)
       }
       if var item = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeOccupancyDetected}.first) {
           item.icon.caption = "Occupancy"
           characteristics.append(item)
       }
       
       if var item = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeCurrentSecuritySystemState}.first) {
           item.icon.caption = "Security"
           characteristics.append(item)
       }
       if var item = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeSecuritySystemAlarmType}.first) {
           item.icon.caption = "Alarm"
           characteristics.append(item)
       }
       if var item = (room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeObstructionDetected}.first) {
           item.icon.caption = "Obstruction"
           characteristics.append(item)
       }
       
       
       // HumidifierDehumidifierState
       var items = room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeCurrentHumidifierDehumidifierState}
       for item in items {
           var item = item
           if let name = item.characteristic?.service?.accessory?.name {
               item.icon.caption = name
           }
           characteristics.append(item)
       }
       // FanState
       items = room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeCurrentFanState}
       for item in items {
           var item = item
           if let name = item.characteristic?.service?.accessory?.name {
               item.icon.caption = name
           }
           characteristics.append(item)
       }
       // PurifierState
       items = room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeCurrentAirPurifierState}
       for item in items {
           var item = item
           if let name = item.characteristic?.service?.accessory?.name {
               item.icon.caption = name
           }
           characteristics.append(item)
       }
       // DoorState
       items = room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeCurrentDoorState}
       for item in items {
           var item = item
           if let name = item.characteristic?.service?.accessory?.name {
               item.icon.caption = name
           }
           characteristics.append(item)
       }
       // LockState
       items = room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeCurrentLockMechanismState}
       for item in items {
           var item = item
           if let name = item.characteristic?.service?.accessory?.name {
               item.icon.caption = name
           }
           characteristics.append(item)
       }
       // StreamingStatus
       items = room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeStreamingStatus}
       for item in items {
           var item = item
           if let name = item.characteristic?.service?.accessory?.name {
               item.icon.caption = name
           }
           characteristics.append(item)
       }
       // Volume
       items = room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeVolume}
       for item in items {
           var item = item
           if let name = item.characteristic?.service?.accessory?.name {
               item.icon.caption = name
           }
           if item.characteristic?.service?.serviceType == HMServiceTypeMicrophone {
               item.icon.name = "mic"
           } else {
               item.icon.name = "speaker"
           }
           characteristics.append(item)
       }
       // Mute
       items = room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeMute}
       for item in items {
           var item = item
           if let name = item.characteristic?.service?.accessory?.name {
               item.icon.caption = name
           }
           if item.characteristic?.service?.serviceType == HMServiceTypeMicrophone {
               item.icon.name = "mic.slash"
           } else {
               item.icon.name = "speaker.slash"
           }
           characteristics.append(item)
       }
       // Night Vision
       items = room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeNightVision}
       for item in items {
           var item = item
           if let name = item.characteristic?.service?.accessory?.name {
               item.icon.caption = name
           }
           characteristics.append(item)
       }
//            // ContactState
//            items = room.characteristics.filter {$0.characteristicType == HMCharacteristicTypeContactState}
//            for item in items {
//                var item = item
//                if let name = item.characteristic?.service?.accessory?.name {
//                    item.icon.caption = name
//                }
//                characteristics.append(item)
//            }
//            // PowerState
//            items = room.characteristics.filter {$0.characteristicType == HMCharacteristicTypePowerState}
//            for item in items {
//                var item = item
//                if let name = item.characteristic?.service?.accessory?.name {
//                    item.icon.caption = name
//                }
//                characteristics.append(item)
//            }
       
       return characteristics
   }
   
   func resetAccessories(room: HKRoom, personal: Bool = false) -> HKRoom {
       var room = room
       func personalTitle(title: String) -> String {
           var title = title
           title = title.replacingOccurrences(of: "Zolder ", with: "")
           title = title.replacingOccurrences(of: "zolder ", with: "")
//                        title = title.replacingOccurrences(of: "Woonkamer ", with: "")
//                        title = title.replacingOccurrences(of: "woonkamer ", with: "")
           title = title.replacingOccurrences(of: "Gang ", with: "")
           title = title.replacingOccurrences(of: "Slaapkamer ", with: "")
           title = title.replacingOccurrences(of: "Vigo ", with: "")
           title = title.replacingOccurrences(of: "Badkamer ", with: "")
           title = title.replacingOccurrences(of: " Switch", with: "")
           title = title.replacingOccurrences(of: " Licht", with: "")
           title = title.replacingOccurrences(of: "Hue", with: "")
           return title
       }
       for (index2, _) in room.lights.enumerated() {
           if room.lights[index2].icon.caption != "" {
               var title = room.lights[index2].name
               if title.count > 30 {
                   title = String(title.prefix(28)) + ".."
               }
               if HWS.personal {
                   title = personalTitle(title: title)
               }
               room.lights[index2].icon.caption = title
               room.lights[index2].icon.captionColor = .customPrimary
           }
       }
       for (index2, _) in room.thermoststats.enumerated() {
           if room.thermoststats[index2].icon.caption != "" {
               var title = room.thermoststats[index2].name
               if title.count > 30 {
                   title = String(title.prefix(28)) + ".."
               }
               if HWS.personal {
                   title = personalTitle(title: title)
               }
               room.thermoststats[index2].icon.caption = title
               room.thermoststats[index2].icon.captionColor = .customPrimary
           }
       }
       for (index2, _) in room.cameras.enumerated() {
           if room.cameras[index2].icon.caption != "" {
               var title = room.cameras[index2].name
               if title.count > 30 {
                   title = String(title.prefix(28)) + ".."
               }
               if HWS.personal {
                   title = personalTitle(title: title)
               }
               room.cameras[index2].icon.caption = title
               room.cameras[index2].icon.captionColor = .customPrimary
           }
       }
       for (index2, _) in room.others.enumerated() {
           if room.others[index2].icon.caption != "" {
               var title = room.others[index2].name
               if title.count > 30 {
                   title = String(title.prefix(28)) + ".."
               }
               if HWS.personal {
                   title = personalTitle(title: title)
               }
               room.others[index2].icon.caption = title
               room.others[index2].icon.captionColor = .customPrimary
           }
       }
       return room
   }
}

struct HKAccessory: Identifiable, Equatable, Hashable, Codable {
    var id = UUID()
    var name = "" // TODO: Name in homekit. Not changed in this app. So change to let
    var caption = ""
    var icon: Icon = Icon(name: "HomeWatchTemplate", color: .customSecondary, caption: "", type: .image)
    var accessory: HMAccessory?
    var accessoryType: String? {
        get {
            return accessory?.category.categoryType
        }
    }
    var powerState: Bool? {
        get {
            let chars = accessory?.services.flatMap { $0.characteristics }
                .filter { $0.characteristicType == HMCharacteristicTypePowerState ||  $0.characteristicType == HMCharacteristicTypeContactState ||  $0.characteristicType == HMCharacteristicTypeCurrentHeatingCooling || $0.characteristicType == HMCharacteristicTypeLeakDetected}
            return chars?.first?.value as? Bool
        }
        set(n) {
            n
        }
    }
    
    var stateValueCurrentTemperature: Float? {
        get {
            let chars = accessory?.services.flatMap { $0.characteristics }
                .filter { $0.characteristicType == HMCharacteristicTypeCurrentTemperature}
            if let valueAny = chars?.first?.value as? Double {
                //
                print ("colw \(chars?.first?.localizedDescription) v \(valueAny)")
                return  Float(valueAny)
                }
            return nil
        }
        set(n) {
            n
        }
    }
    
    var stateValueTargetTemperature: Float? {
        get {
            let chars = accessory?.services.flatMap { $0.characteristics }
                .filter { $0.characteristicType == HMCharacteristicTypeTargetTemperature}
            if let valueAny = chars?.first?.value as? Double {
                //print ("colw \(chars?.first?.localizedDescription) v \(valueAny)")
                return  Float(valueAny)
                }
            return nil
        }
        set(n) {
            n
        }
    }
    
    
   
    
    var stateFloat: Float? {
        get {
            let chars = accessory?.services.flatMap { $0.characteristics }
                .filter { $0.characteristicType == HMCharacteristicTypeCurrentHeatingCooling || $0.characteristicType == HMCharacteristicTypeCarbonDioxideLevel}
            
            var v = chars?.first?.value as? Float
            if v == nil {
                if let i = chars?.first?.value as? Int {
                    v = Float(i)
                }
               
            }
            print ("colw \(chars?.first?.localizedDescription) v \(chars?.first?.value)")
            return v
        }
        set(n) {
            n
        }
    }
    
    var update: Bool? = false
    var services: [HKService]? = []
    var characteristics: [HKCharacteristic]? = []
    
   
    var color: Color?
}

// Update, Load and Save HKAccessory
extension HKAccessory {
    mutating func updateAccessoryfromID(accessories: [HKAccessory]) {
        var accessory: HKAccessory?
        if let _accessory = accessories.first(where: {$0.id == id}) {
            accessory = _accessory
            id = accessory?.id ?? id
        } else if let _accessory = accessories.first(where: {$0.name == name}) {
            accessory = _accessory
            id = accessory?.id ?? id
        }
        self.accessory = accessory?.accessory ?? self.accessory
    }
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case caption
        case icon
    }
}

// Convenience Functions
extension HKAccessory {
    
   
    
    mutating func setDefaultIconForAccessory() {
        if let icon = getDefaultIconForAccessory(accessoryType) {
            self.icon = icon
            return
        }
       
        if let service = accessory?.services.first(where: {$0.serviceType != HMServiceTypeBattery }) {
            if let icon = getDefaultIconForService(service.serviceType) {
                self.icon = icon
                return
            }
        }
        self.icon = Icon(name: "circle", color: .white, caption: self.name, captionLocation: .bottom, type: .symbol)
        var teller = 0
        let services = accessory?.services.compactMap{$0} ?? []
        for service in services {
            let chars = (service.characteristics)
            for char in chars {
                teller = teller + 1
                if let icon = HKCharacteristic().getDefaultIconForCharacteristic(char.characteristicType), char.characteristicType != HMCharacteristicTypeBatteryLevel, char.characteristicType != HMCharacteristicTypeStatusLowBattery  {
                    self.icon = icon
                    if service.isPrimaryService {return}
                }
            }
        }
        
        
     //   }
        
        
//        if let icon = getDefaultIconForAccessory(accessoryType) {
//            self.icon = icon
//        } else {
//            self.icon = Icon(name: "circle", color: .white, caption: self.name, captionLocation: .bottom, type: .symbol)
//            var teller = 0
//            let services = accessory?.services.compactMap{$0} ?? []
//            for service in services {
//                let chars = (service.characteristics)
//                for char in chars {
//                    teller = teller + 1
//                    if let icon = HKCharacteristic().getDefaultIconForAccessory(char.characteristicType) {
//                        self.icon = icon
//                        if service.isPrimaryService {return}
//                    }
//                }
//            }
//        }
    }
    
    func getDefaultIconForAccessory(_ categoryType: String?) -> Icon? {
        switch categoryType {
        case HMAccessoryCategoryTypeLightbulb:
            return Icon(name: "lightbulb", color: .white, caption: "", type: .symbol)
        case HMAccessoryCategoryTypeOutlet:
            return Icon(name: "togglepower", color: .white, caption: "", type: .symbol)
        case HMAccessoryCategoryTypeSwitch:
            if #available(iOS 16, watchOS 9, tvOS 16, *) {
                return Icon(name: "lightswitch.on.square", color: .white, caption: "", type: .symbol)
            } else {
                return Icon(name: "switch.2", color: .white, caption: "", type: .symbol)
            }
        case HMAccessoryCategoryTypeProgrammableSwitch:
            if #available(iOS 16, watchOS 9, tvOS 16, *) {
                return Icon(name: "switch.programmable.square", color: .white, caption: "", type: .symbol)
            } else {
                return Icon(name: "switch.2", color: .white, caption: "", type: .symbol)
            }
        case HMAccessoryCategoryTypeFan, HMAccessoryCategoryTypeAirPurifier:
            return Icon(name: "fanblades", color: .white, caption: "", type: .symbol)
        case HMAccessoryCategoryTypeThermostat, HMAccessoryCategoryTypeAirConditioner, HMAccessoryCategoryTypeAirHeater:
            return Icon(name: "thermometer", color: .white, caption: "", type: .symbol)
        case HMAccessoryCategoryTypeAirDehumidifier, HMAccessoryCategoryTypeAirHumidifier, HMAccessoryCategoryTypeSprinkler, HMAccessoryCategoryTypeFaucet, HMAccessoryCategoryTypeShowerHead:
            return Icon(name: "humidity", color: .white, caption: "", type: .symbol)
        case HMAccessoryCategoryTypeWindow, HMAccessoryCategoryTypeWindowCovering:
            if #available(iOS 16, watchOS 9, tvOS 16, *) {
                return Icon(name: "window.vertical.closed", color: .white, caption: "", type: .symbol)
            } else {
                return Icon(name: "uiwindow.split.2x1", color: .white, caption: "", type: .symbol)
            }
        case HMAccessoryCategoryTypeDoor:
            if #available(iOS 16, watchOS 9, tvOS 16, *) {
                return Icon(name: "door.left.hand.closed", color: .white, caption: "", type: .symbol)
            } else {
                return Icon(name: "rectangle.portrait", color: .white, caption: "", type: .symbol)
            }
        case HMAccessoryCategoryTypeDoorLock, HMAccessoryCategoryTypeGarageDoorOpener, HMAccessoryCategoryTypeSensor, HMAccessoryCategoryTypeSecuritySystem:
            return Icon(name: "lock", color: .white, caption: "", type: .symbol)
        case HMAccessoryCategoryTypeVideoDoorbell, HMAccessoryCategoryTypeIPCamera:
            return Icon(name: "video", color: .white, caption: "", type: .symbol)
        case HMAccessoryCategoryTypeBridge, HMAccessoryCategoryTypeRangeExtender:
            return Icon(name: "network", color: .white, caption: "", type: .symbol)
        case HMAccessoryCategoryTypeSecuritySystem:
            return Icon(name: "lock.shield", color: .white, caption: "", type: .symbol)
        case HMAccessoryCategoryTypeShowerHead:
            return Icon(name: "shower", color: .white, caption: "", type: .symbol)
        case HMAccessoryCategoryTypeFaucet:
            return Icon(name: "spigot", color: .white, caption: "", type: .symbol)
        case HMAccessoryCategoryTypeSprinkler:
            return Icon(name: "sprinkler", color: .white, caption: "", type: .symbol)
        default:
            return nil
        }
    }
    
    func getDefaultIconForService(_ serviceType: String?) -> Icon? {
    //        if "giic \(name) \(service?.serviceType.localizedDescription)" != nil {
    //            print ("giic \(name) \(service?.serviceType.localizedDescription)")
    //        }
        switch serviceType {
        case HMServiceTypeLightbulb:
            return Icon(name: "lightbulb", color: .white, caption: "", type: .symbol)
        case HMServiceTypeOutlet:
            return Icon(name: "togglepower", color: .white, caption: "", type: .symbol)
        case  HMServiceTypeSwitch:
            if #available(iOS 16, watchOS 9, tvOS 16, *) {
                return Icon(name: "lightswitch.on.square", color: .white, caption: "", type: .symbol)
            } else {
                return Icon(name: "switch.2", color: .white, caption: "", type: .symbol)
            }
        case  HMServiceTypeSwitch, HMServiceTypeStatefulProgrammableSwitch, HMServiceTypeStatelessProgrammableSwitch:
            if #available(iOS 16, watchOS 9, tvOS 16, *) {
                return Icon(name: "switch.programmable.square", color: .white, caption: "", type: .symbol)
            } else {
                return Icon(name: "switch.2", color: .white, caption: "", type: .symbol)
            }
        case HMServiceTypeFan, HMServiceTypeAirPurifier:
            return Icon(name: "fanblades", color: .white, caption: "", type: .symbol)
        case HMServiceTypeThermostat, HMServiceTypeHeaterCooler, HMServiceTypeTemperatureSensor:
            return Icon(name: "thermometer", color: .white, caption: "", type: .symbol)
        case HMServiceTypeHumiditySensor, HMServiceTypeHumidifierDehumidifier:
            return Icon(name: "humidity", color: .white, caption: "", type: .symbol)
        case HMServiceTypeWindow, HMServiceTypeWindowCovering:
            if #available(iOS 16, watchOS 9, tvOS 16, *) {
                return Icon(name: "window.vertical.closed", color: .white, caption: "", type: .symbol)
            } else {
                return Icon(name: "uiwindow.split.2x1", color: .white, caption: "", type: .symbol)
            }
        case HMServiceTypeDoor:
            if #available(iOS 16, watchOS 9, tvOS 16, *) {
                return Icon(name: "door.left.hand.closed", color: .white, caption: "", type: .symbol)
            } else {
                return Icon(name: "rectangle.portrait", color: .white, caption: "", type: .symbol)
            }
        case HMServiceTypeMotionSensor:
            if #available(iOS 16, watchOS 9, tvOS 16, *) {
                return Icon(name: "figure.walk.motion", color: .white, caption: "", type: .symbol)
            } else {
                return Icon(name: "figure.walk", color: .white, caption: "", type: .symbol)
            }
        case HMServiceTypeOccupancySensor:
            return Icon(name: "person", color: .white, caption: "", type: .symbol)
        case HMServiceTypeCameraControl, HMServiceTypeCameraRTPStreamManagement:
            return Icon(name: "camera", color: .white, caption: "", type: .symbol)
        case HMServiceTypeMicrophone:
            return Icon(name: "mic", color: .white, caption: "", type: .symbol)
        case HMServiceTypeSpeaker:
            return Icon(name: "speaker", color: .white, caption: "", type: .symbol)
        default:
            return nil
        }
    }
    
    mutating func getCharacteristicsForAccessoryState() -> [HMCharacteristic] {
        let chars = accessory?.services.flatMap{ $0.characteristics }
        
        let filtered = chars?.filter { $0.characteristicType == HMCharacteristicTypeContactState || $0.characteristicType == HMCharacteristicTypeCarbonDioxideLevel || $0.characteristicType == HMCharacteristicTypeCarbonMonoxideLevel || $0.characteristicType == HMCharacteristicTypeCurrentHeatingCooling || $0.characteristicType == HMCharacteristicTypeAirQuality ||  $0.characteristicType == HMCharacteristicTypeOccupancyDetected || $0.characteristicType == HMCharacteristicTypeMotionDetected || $0.characteristicType == HMCharacteristicTypeMute || $0.characteristicType == HMCharacteristicTypeCurrentSecuritySystemState || $0.characteristicType == HMCharacteristicTypeLeakDetected || $0.characteristicType == HMCharacteristicTypeVolatileOrganicCompoundDensity || $0.characteristicType == HMCharacteristicTypeStatusLowBattery || $0.characteristicType == HMCharacteristicTypeCurrentLockMechanismState }
        return filtered ?? []
    }
    
    mutating func getCharacteristicsForAccessoryPowersStateAndThermostat() -> [HMCharacteristic] {
        let chars = accessory?.services.flatMap{ $0.characteristics }
        let filtered = chars?.filter { $0.characteristicType == HMCharacteristicTypePowerState || $0.characteristicType == HMCharacteristicTypeCurrentHeatingCooling || $0.characteristicType == HMCharacteristicTypeTargetHeatingCooling }
        return filtered ?? []
    }
    
    mutating func getValueForCharacteristicType(characteristicType: String) -> Float {
        let chars = accessory?.services.flatMap{ $0.characteristics }
        let filtered = chars?.filter{ $0.characteristicType == characteristicType}.first
        return filtered?.value as? Float ?? 0
        
    }
    
    func getIconForCharacteristicState(_ characterisitic: HMCharacteristic) -> (Bool,String)? {
      //  let allChars = self.accessory?.services.flatMap{$0.characteristics}
      //  print ("iconfor \(allChars?.count)")
      //  let char = allChars?.first(where: {$0.characteristicType == characteristicType})
        
        // Supported
        // Contact State
        // Air Quality, CarbonDioxide Level, CabonMonoxide Level, HMCharacteristicTypeVolatileOrganicCompoundDensity (Add mor climate stuff)
        // CurrentHeatingCooling
        // Occupancy, Motion
        // leak
        // low battery
        
        // Add? fan humidifer?
        
        
        guard let value = characterisitic.value else {return nil}
        let characteristicType = characterisitic.characteristicType
        switch characteristicType {
        case HMCharacteristicTypeContactState:
            guard let state = value as? Bool else { return nil}
            if #available(iOS 16, watchOS 9, tvOS 16, *) {
                return state ? (true,"contact.sensor.fill") : (false,"contact.sensor")
            } else {
                return state ? (true,"square.fill") : (false,"square.on.square.dashed")
            }
        case HMCharacteristicTypeCarbonDioxideLevel:
            guard let state = value as? Float else { return nil}
            return state > 1000 ? (true,"carbon.dioxide.cloud.fill") : (false,"carbon.dioxide.cloud")
        case HMCharacteristicTypeCarbonMonoxideLevel:
            guard let state = value as? Float else { return nil}
            return state > 150 ? (true,"carbon.monoxide.cloud.fill") : (false,"carbon.monoxide.cloud")
//        case HMCharacteristicTypePM2_5Density:
//            guard let state = value as? Float else { return nil}
//            return state > 55 ? (true,"carbon.monoxide.cloud.fill") : (false,"carbon.monoxide.cloud")
//        case HMCharacteristicTypePM10Density:
//            guard let state = value as? Float else { return nil}
//            return state > 55 ? (true,"carbon.monoxide.cloud.fill") : (false,"carbon.monoxide.cloud")
        case HMCharacteristicTypeVolatileOrganicCompoundDensity:
            guard let state = value as? Float else { return nil}
            return state > 3000 ? (true,"aqi.high") : (false,"aqi.medium")
        case HMCharacteristicTypeCurrentHeatingCooling:
            guard let state = value as? Int else { return nil}
            if #available(iOS 16, watchOS 9, tvOS 16, *) {
                return state > 0 ? (true,"air.conditioner.vertical.fill") : (false,"air.conditioner.vertical")
            } else {
                return state > 0 ? (true,"square.fill") : (false,"square")
            }
        case HMCharacteristicTypeAirQuality:
            guard let state = value as? Int else { return nil}
            return state > 3  ? (true,"leaf.fill") : (false,"leaf")
        case HMCharacteristicTypeOccupancyDetected:
            print ("iconfor HMCharacteristicTypeOccupancyDetected")
            guard let state = value as? Bool else { return nil}
            return state ? (true,"person.fill") : (false,"person")
        case HMCharacteristicTypeMotionDetected:
            print ("iconfor HMCharacteristicTypeMotionDetected")
            guard let state = value as? Bool else { return nil}
            if #available(iOS 16, watchOS 9, tvOS 16, *) {
                return state ? (true,"figure.walk.motion") : (false,"figure.walk.motion")
            } else {
                return state ? (true,"figure.walk") : (false,"figure.walk")
            }
        case HMCharacteristicTypeCurrentLockMechanismState:
            guard let state = value as? Int else { return nil}
            return state == 1 ? (true,"lock") : (false,"lock.slash")
        case HMCharacteristicTypeLeakDetected:
            guard let state = value as? Int else { return nil}
            return state > 0 ? (true,"drop.fill") : (false,"drop")
        case HMCharacteristicTypeMute:
            guard let state = value as? Bool else { return nil}
            if characterisitic.service?.serviceType == HMServiceTypeSpeaker {
                return state ? (true,"speaker.slash") : (false,"speaker")
            } else {
                return state ? (true,"mic.slash") : (false,"mic")
            }
        case HMCharacteristicTypeStatusLowBattery:
            guard let state = value as? Int else { return nil}
            return state > 0 ? (true,"battery.0") : (false,"battery.75")
        default:
            return nil
        }
    }
}

struct HKService: Identifiable, Equatable, Hashable, Codable {
    var id = UUID()
    var name = "" // TODO: Name in homekit. Not changed in this app. So change to let
    var caption = ""
    var icon: Icon = Icon(name: "HomeWatchTemplate", color: .customSecondary, caption: "", type: .image)
    var service: HMService?
    var characteristics: [HKCharacteristic] = []
//    var accessoryType: String? {
//        get {
//            return accessory?.category.categoryType
//        }
//    }
    
  
}

extension HKService {
    enum CodingKeys: CodingKey {
        case id
        case name
        case caption
        case icon
        case characteristics
    }
}

extension HKService {
    func getDefaultIconForService(_ serviceType: String?) -> Icon? {
    //        if "giic \(name) \(service?.serviceType.localizedDescription)" != nil {
    //            print ("giic \(name) \(service?.serviceType.localizedDescription)")
    //        }
        switch serviceType {
        case HMServiceTypeLightbulb:
            return Icon(name: "lightbulb", color: .white, caption: "", type: .symbol)
        case HMServiceTypeOutlet:
            return Icon(name: "togglepower", color: .white, caption: "", type: .symbol)
        case  HMServiceTypeSwitch:
            if #available(iOS 16, watchOS 9, tvOS 16, *) {
                return Icon(name: "lightswitch.on.square", color: .white, caption: "", type: .symbol)
            } else {
                return Icon(name: "switch.2", color: .white, caption: "", type: .symbol)
            }
        case  HMServiceTypeStatefulProgrammableSwitch, HMServiceTypeStatelessProgrammableSwitch:
            if #available(iOS 16, watchOS 9, tvOS 16, *) {
                return Icon(name: "switch.programmable.square", color: .white, caption: "", type: .symbol)
            } else {
                return Icon(name: "switch.2", color: .white, caption: "", type: .symbol)
            }
        case HMServiceTypeFan, HMServiceTypeAirPurifier:
            return Icon(name: "fanblades", color: .white, caption: "", type: .symbol)
        case HMServiceTypeThermostat, HMServiceTypeHeaterCooler, HMServiceTypeTemperatureSensor:
            return Icon(name: "thermometer", color: .white, caption: "", type: .symbol)
        case HMServiceTypeHumiditySensor, HMServiceTypeHumidifierDehumidifier:
            return Icon(name: "humidity", color: .white, caption: "", type: .symbol)
        case HMServiceTypeWindow, HMServiceTypeWindowCovering:
            return Icon(name: "uiwindow.split.2x1", color: .white, caption: "", type: .symbol)
        case HMServiceTypeDoor:
            return Icon(name: "rectangle.portrait", color: .white, caption: "", type: .symbol)
        case HMServiceTypeMotionSensor:
            return Icon(name: "figure.walk.motion", color: .white, caption: "", type: .symbol)
        case HMServiceTypeOccupancySensor:
            return Icon(name: "person", color: .white, caption: "", type: .symbol)
        case HMServiceTypeCameraControl, HMServiceTypeCameraRTPStreamManagement:
            return Icon(name: "camera", color: .white, caption: "", type: .symbol)
        case HMServiceTypeMicrophone:
            return Icon(name: "mic", color: .white, caption: "", type: .symbol)
        case HMServiceTypeSpeaker:
            return Icon(name: "speaker", color: .white, caption: "", type: .symbol)
        default:
            return nil
        }
    }
}

struct HKCharacteristic: Identifiable, Equatable, Hashable, Codable {
    var id = UUID()
    var name = "" // TODO: Name in homekit. Not changed in this app. So change to let
    var caption = ""
    var icon: Icon = Icon(name: "HomeWatchTemplate", color: .customSecondary, caption: "", type: .image)
    var characteristic: HMCharacteristic?
    var characteristicType: String? {
        get {
            characteristic?.characteristicType
        }
    }
    var value: Any? {
        get {
            return characteristic?.value
        }
        set(n) {
            n
        }
    }
    var valueSlider: Float?
    var update: Bool?
}

// Update, Load and Save HKCharacteristic
extension HKCharacteristic {
    enum CodingKeys: CodingKey {
        case id
        case name
        case caption
        case icon
    }
    
    mutating func updateCharacteristicfromID(characteristics: [HKCharacteristic]) {
        var characteristic: HKCharacteristic?
        
        if let _characteristic = characteristics.first(where: {$0.id == id}) {
            characteristic = _characteristic
            id = characteristic?.id ?? id
        } else if let _characteristic = characteristics.first(where: {$0.name == name}) {
            characteristic = _characteristic
            id = characteristic?.id ?? id
            // TODO: NB save new id
        }
        self.characteristic = characteristic?.characteristic ?? self.characteristic
    }
}

// Convenience Functions
extension HKCharacteristic {
    func getStringForValue() -> String? {
        var string: String?
        let value = characteristic?.value
        //print ("iconfor \(name) \(characteristic?.characteristicType.description)")
        switch characteristic?.metadata?.format {
        case HMCharacteristicMetadataFormatBool:
            if let bool = value as? Bool {
                if characteristicType ==  HMCharacteristicTypePowerState {
                    string =  bool ? "On" : "Off"
                } else if characteristicType == HMCharacteristicTypeContactState {
                    string =  bool ? "Open" : "Closed"
                } else {
                    string =  bool ? "True" : "False"
                }
            }
        case HMCharacteristicMetadataFormatString:
            if let _string = value as? String {
                let units = (characteristic?.metadata?.units != nil ? " " + (characteristic?.metadata?.units ?? "") : "")
                if icon.caption == "" {
                    string = _string + units
                } else {
                    string = _string
                }
            }
        default:
            switch characteristic?.characteristicType {
            case HMCharacteristicTypeContactState:
                string = (value as? Int ?? 0) == 1 ? "Open" : "Closed"
            case HMCharacteristicTypeLeakDetected:
                string = (value as? Int ?? 0) == 1 ? "Yes" : "No"
            case HMCharacteristicTypeStatusLowBattery:
                string = (value as? Int ?? 0) == 1 ? "Low" : "Normal"
            case HMCharacteristicTypeLockPhysicalControls:
                string = (value as? Int ?? 0) == 1 ? "Locked" : "Not Locked"
            case HMCharacteristicTypeCarbonDioxideDetected, HMCharacteristicTypeCarbonMonoxideDetected, HMCharacteristicTypeSmokeDetected, HMCharacteristicTypeMotionDetected, HMCharacteristicTypeOccupancyDetected, HMCharacteristicTypeObstructionDetected:
                string = (value as? Int ?? 0) == 1 ? "Detected" : "No"
            case HMCharacteristicTypeCurrentHeatingCooling :
                let value = (value as? Int ?? 0)
                if value == 1 {
                    string = "Heat"
                } else if value == 2 {
                    string = "Cool"
                } else if value == 3 {
                    string = "Auto"
                } else {
                 string = "Off"
                }
            case HMCharacteristicTypeTargetHeaterCoolerState:
                let value = (value as? Int ?? 0)
                if value == 1 {
                    string = "Heat"
                } else if value == 2 {
                    string = "Cool"
                } else {
                 string = "Automatic"
                }
            case HMCharacteristicTypeCurrentFanState, HMCharacteristicTypeCurrentAirPurifierState:
                let value = (value as? Int ?? 0)
                if value == 1 {
                    string = "Idle"
                } else if value == 2 {
                    string = "Active"
                } else {
                 string = "Inactive"
                }
            case HMCharacteristicTypeTargetFanState, HMCharacteristicTypeTargetAirPurifierState:
                string = (value as? Int ?? 0) == 1 ? "Manual" : "Automatic"
            case HMCharacteristicTypeCurrentHumidifierDehumidifierState :
                let value = (value as? Int ?? 0)
                if value == 1 {
                    string = "Idle"
                } else if value == 2 {
                    string = "Humidifying"
                } else if value == 3 {
                    string = "Dehumidifying"
                } else {
                 string = "Inactive"
                }
            case HMCharacteristicTypeTargetHumidifierDehumidifierState :
                let value = (value as? Int ?? 0)
                if value == 1 {
                    string = "Humidify"
                } else if value == 2 {
                    string = "Dehumidify"
                } else {
                 string = "Automatic"
                }
            case HMCharacteristicTypeCurrentDoorState, HMCharacteristicTypeTargetDoorState:
                let value = (value as? Int ?? 0)
                if value == 1 {
                    string = "Closed"
                } else if value == 2 {
                    string = "Opening"
                } else if value == 3 {
                    string = "Closing"
                } else if value == 4 {
                    string = "Stopped"
                } else {
                 string = "Open"
                }

            case HMCharacteristicTypeColorTemperature:
                string = String(value as? Int ?? 1) + "Mired " + String(1000000 / (value as? Int ?? 1)) + "K"
            case HMCharacteristicTypeInputEvent:
                let value = (value as? Int ?? 0)
                if value == 1 {
                    string = "DoublePress"
                } else if value == 2 {
                    string = "LongPress"
                
                } else {
                 string = "SinglePress"
                }
            case HMCharacteristicTypeTemperatureUnits:
                string = (value as? Int ?? 0) == 0 ? "Celsius" : "Fahrenheit"
            
            case HMCharacteristicTypeCurrentSecuritySystemState, HMCharacteristicTypeTargetSecuritySystemState:
                let value = (value as? Int ?? 0)
                if value == 1 {
                    string = "Away Arm"
                } else if value == 2 {
                    string = "Night Arm"
                } else if value == 3 {
                    string = "Disarmed"
                } else if value == 4 {
                    string = "Triggered"
                } else {
                 string = "Home Arm"
                }
            case HMCharacteristicTypeSecuritySystemAlarmType:
                string = (value as? Int ?? 0) == 1 ? "No Alarm" : "Unknown"
                
            case HMCharacteristicTypeCurrentLockMechanismState, HMCharacteristicTypeTargetLockMechanismState:
                let value = (value as? Int ?? 0)
                if value == 1 {
                    string = "Secured"
                } else if value == 2 {
                    string = "Jammed"
                } else if value == 3 {
                    string = "Unknown"
                } else {
                 string = "Unsecured"
                }
               
            case HMCharacteristicTypeAirQuality:
                //print ("sic format \(characteristic?.metadata)")
                let characteristicValueAirQuality: HMCharacteristicValueAirQuality = HMCharacteristicValueAirQuality(rawValue: (value as? Int ?? 0)) ?? HMCharacteristicValueAirQuality.unknown
                switch characteristicValueAirQuality {
                case .unknown:
                    string = "Unknown"
                case .excellent:
                    string = "Excellent"
                case .good:
                    string = "Good"
                case .fair:
                    string = "Fair"
                case .inferior:
                    string = "Inferior"
                case .poor:
                    string = "Poor"
                default:
                    string = "Unknown"
                }
                
            case HMCharacteristicTypeCarbonDioxideLevel:
                let tempValue = self.value
                string = String((tempValue as? Double ?? 0).rounded(toPlaces: 1)) + " ppm"
                
            case HMCharacteristicTypePM2_5Density, HMCharacteristicTypePM10Density, HMCharacteristicTypeVolatileOrganicCompoundDensity, HMCharacteristicTypeNitrogenDioxideDensity, HMCharacteristicTypeOzoneDensity, HMCharacteristicTypeSulphurDioxideDensity:
                let tempValue = self.value
                string = String((tempValue as? Double ?? 0).rounded(toPlaces: 1)) + " μg/m³"
                
            case HMCharacteristicTypeStreamingStatus:
               string = self.value as? String ?? ""
              
            case HMCharacteristicTypeVolume:
                let tempValue = self.value
                string = String((tempValue as? Double ?? 0).rounded(toPlaces: 1)) + " %"
                
            case HMCharacteristicTypeMute:
                string = (value as? Int ?? 0) == 1 ? "Muted" : "Not Muted"
            default:
                var units = (characteristic?.metadata?.units != nil ? " " + (characteristic?.metadata?.units ?? "") : "")
                var tempValue = self.value
                if units.lowercased().contains("celsius") {
                    if !Weather.shared.imperialUnits {
                        units = " °C"
                    } else {
                        units = " °F"
                        tempValue = celsiusToFahrenheitAsDouble(celsius:value as? Double ?? 0)
                    }
                }
                if units.lowercased().contains("percentage") {units = " %"}
                if icon.caption == "" || icon.caption == " "  {
                    string = String((tempValue as? Double ?? 0).rounded(toPlaces: 1)) + units
                } else {
                    string = String((tempValue as? Double ?? 0).rounded(toPlaces: 1))
                }
            }
        }
        return string
    }
    
    mutating func setDefaultIconForCharacteristic() {
        if let icon = getDefaultIconForCharacteristic(characteristicType) {
            self.icon = icon
        } else {
            if let accessory = characteristic?.service?.accessory,  let service = accessory.services.first(where: {$0.isPrimaryService == true && $0.serviceType != HMServiceTypeBattery }),  let icon = HKAccessory().getDefaultIconForService(service.serviceType) {
                self.icon = icon }
            else if let accessory = characteristic?.service?.accessory {
                icon = HKAccessory().getDefaultIconForAccessory(accessory.category.categoryType) ?? Icon(name: "circle", color: .white, caption: "", type: .symbol)
            } else {
                icon = Icon(name: "circle", color: .white, caption: "", type: .symbol)
            }
        }
    }
    
    func getDefaultIconForCharacteristic(_ characteristicType: String?) -> Icon? {
        switch characteristicType {
        case HMCharacteristicTypePowerState, HMCharacteristicTypeOutletInUse:
            return Icon(name: "power", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeCurrentTemperature, HMCharacteristicTypeTargetTemperature, HMCharacteristicTypeCurrentHeatingCooling, HMCharacteristicTypeTargetHeatingCooling:
            return Icon(name: "thermometer", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeCurrentRelativeHumidity, HMCharacteristicTypeTargetRelativeHumidity:
            return Icon(name: "humidity", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeCurrentHumidifierDehumidifierState,
        HMCharacteristicTypeTargetHumidifierDehumidifierState, HMCharacteristicTypeHumidifierThreshold, HMCharacteristicTypeDehumidifierThreshold:
            return Icon(name: "dehumidifier", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeAirQuality:
            return Icon(name: "leaf", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypePM2_5Density, HMCharacteristicTypeAirParticulateDensity, HMCharacteristicTypeAirParticulateSize:
            return Icon(name: "aqi.low", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypePM10Density:
            return Icon(name: "aqi.medium", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeCarbonMonoxideLevel:
            return Icon(name: "carbon.monoxide.cloud", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeCarbonDioxideLevel:
            return Icon(name: "carbon.dioxide.cloud", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeVolatileOrganicCompoundDensity:
            return Icon(name: "allergens", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeSmokeDetected:
            return Icon(name: "smoke", color: .white, caption: "", type: .symbol)
        case  HMCharacteristicTypeCarbonMonoxideDetected, HMCharacteristicTypeCarbonMonoxideLevel, HMCharacteristicTypeCarbonMonoxidePeakLevel:
            return Icon(name: "carbon.monoxide.cloud", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeCarbonDioxideDetected, HMCharacteristicTypeCarbonDioxideLevel, HMCharacteristicTypeCarbonDioxidePeakLevel:
            return Icon(name: "carbon.dioxide.cloud", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeWaterLevel, HMCharacteristicTypeValveType, HMCharacteristicTypeLeakDetected:
            return Icon(name: "drop", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeChargingState:
            return Icon(name: "battery.75", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeBatteryLevel:
            return Icon(name: "battery.100", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeStatusLowBattery:
            return Icon(name: "battery.0", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeMotionDetected:
            return Icon(name: "figure.walk.motion", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeOccupancyDetected:
            return Icon(name: "person", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeContactState:
            return Icon(name: "contact.sensor", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeOutputState:
            return Icon(name: "switch.programmable.square", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeInputEvent:
            return Icon(name: "switch.programmable.square", color: .white, caption: "", type: .symbol)
        case    HMCharacteristicTypeCurrentFanState, HMCharacteristicTypeTargetFanState, HMCharacteristicTypeRotationDirection, HMCharacteristicTypeRotationSpeed, HMCharacteristicTypeSwingMode:
            return Icon(name: "fanblades", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeCurrentAirPurifierState, HMCharacteristicTypeTargetAirPurifierState, HMCharacteristicTypeFilterLifeLevel, HMCharacteristicTypeFilterChangeIndication, HMCharacteristicTypeFilterResetChangeIndication:
            return Icon(name: "air.purifier", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeCurrentDoorState, HMCharacteristicTypeTargetDoorState:
            return Icon(name: "door.left.hand.closed", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeCurrentLockMechanismState, HMCharacteristicTypeTargetLockMechanismState:
            return Icon(name: "key", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeCurrentSecuritySystemState, HMCharacteristicTypeTargetSecuritySystemState:
            return Icon(name: "shield", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeObstructionDetected, HMCharacteristicTypeSecuritySystemAlarmType:
            return Icon(name: "exclamationmark.shield", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeNightVision:
            return Icon(name: "eye.square.fill", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeStreamingStatus:
            return Icon(name: "video", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeVolume:
            return Icon(name: "speaker.wave.3", color: .white, caption: "", type: .symbol)
        case HMCharacteristicTypeMute:
            return Icon(name: "speaker.slash", color: .white, caption: "", type: .symbol)
        default:
            return nil
        }
    }
    
    
}



struct HKScene: Identifiable, Equatable, Hashable, Codable {
    var id = UUID()
    var name = "" // TODO: Name in homekit. Not changed in this app. So change to let
    var caption = "" // Room name as displayed in this app
    var icon: Icon = Icon(name: "HomeWatchTemplate", color: .customSecondary, caption: "", type: .image)
    var accessoryType: AccessoryType = .none
    var actionType: ActionType = .none
    var sceneToCall: SceneToCall = .actionSet
    var active = false
    var isExecuting: Bool? {
        get {
            var test: Bool? = true
            guard let scene = scene else {
                print ("sts false")
                return false}
            for action in scene.actions {
                if let _action = action as? HMCharacteristicWriteAction<NSCopying> {
                    // TODO: NB we are only comparing any values that can be downcasted to int
                    let target = _action.targetValue as? Int
                    let value = _action.characteristic.value as? Int
                    if target != value {
                        test = false
                        if value != nil && target != nil {
                           
                        }
                    }
                    print ("sts \(scene.name) tar \(target) val \(value)")
                    print ("sts1 \(scene.name) tar \(_action.targetValue) val \(_action.characteristic.value)")
                }
            }
            return test
        }
    }
    var scene: HMActionSet?
    var isActive: Bool? {
        get {
          
            return scene?.isExecuting
        }
        set(n) {
            n
        }
    }
    var update: Bool?

//    static func == (lhs: HKRoomScene, rhs:HKRoomScene) -> Bool {
//        return lhs.id == rhs.id
//    }
}

extension HKScene {
    mutating func updateScenefromID() {
        
        if HomekitStore.shared.home.getAllScenes().first(where: {$0.id == id}) == nil {
            print (">>> A scene not found \(name)")
            if  let _scene = HomekitStore.shared.home.getAllScenes().first(where: {$0.name == name}) {
                id = _scene.id
                print (">>> matched scene by name \(name)")
                // TODO: NB save new id
            } else {
                print (">>> B scene not found \(name)")
            }
        }
        
        guard let scene = HomekitStore.shared.home.getAllScenes().first(where: {$0.id == id}) else {
            print (">>> scene not found \(name)")
            return
        }
        print (">>> lcc scene updated")
        self.scene = scene.scene
    }
    
    func getAllcharacteristiscsForScene() -> [HMCharacteristic] {
        var characteristics: [HMCharacteristic]  = []
            if let a = scene?.actions {
                for action in a {
                    if let _action = action as? HMCharacteristicWriteAction<NSCopying> {
                        characteristics.append(_action.characteristic)
                    }
                }
            }
        return characteristics
    }

    
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case caption
        case icon
        case accessoryType
        case sceneToCall
        case active
    }
}

// TODO: Add Structs for the main accessories types back in here and

