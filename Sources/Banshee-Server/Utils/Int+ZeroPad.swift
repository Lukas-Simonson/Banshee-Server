import Foundation

extension Int {
    func pad(_ count: Int = 3) -> String {
        String(format: "$0\(count)", self)
    }
}