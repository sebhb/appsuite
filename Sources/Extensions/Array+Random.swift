import Foundation

extension Array {

    mutating func randomElementByRemoving() -> Element? {
        if isEmpty {
            return nil
        }
        let randomIndex = Int.random(in: 0..<count)
        return remove(at: randomIndex)
    }

}
