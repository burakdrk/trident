//
//  Array+unique.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-05.
//

extension Array {
    func unique<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        var uniqueElements: [Element] = []

        for element in self {
            let value = element[keyPath: keyPath]
            if seen.insert(value).inserted {
                uniqueElements.append(element)
            }
        }

        return uniqueElements
    }
}
