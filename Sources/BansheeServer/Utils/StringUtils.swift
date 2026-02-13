extension String {
    var seconds: Int? {
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
    
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

extension Optional<String> {
    var emptyIfNil: String {
        self ?? ""
    }
}
