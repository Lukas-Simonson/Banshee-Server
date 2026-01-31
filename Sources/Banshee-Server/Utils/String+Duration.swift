//
//  String+Duration.swift
//  Banshee-Server
//
//  Created by Lukas Simonson on 1/31/26.
//

extension String {
    var timeStringSeconds: Int? {
        let components = split(separator: ":").compactMap { Int($0) }
        
        guard !components.isEmpty && components.count <= 4 else {
            return nil
        }
        
        var totalSeconds = 0
        let multipliers = [86400, 3600, 60, 1] // days, hours, minutes, seconds
        
        // Start from the end (seconds) and work backwards
        let startIndex = multipliers.count - components.count
        
        for (index, component) in components.enumerated() {
            totalSeconds += component * multipliers[startIndex + index]
        }
        
        return totalSeconds
    }
}


