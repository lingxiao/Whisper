//
//  ArrayExtension.swift
//  byte
//
//  Created by Xiao Ling on 5/22/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation

extension Array{
    public mutating func pushUnique<S>(contentsOf newElements: S, where condition:@escaping (Element, Element) -> Bool) where S : Sequence, Element == S.Element {
      newElements.forEach { (item) in
        if !(self.contains(where: { (selfItem) -> Bool in
            return !condition(selfItem, item)
        })) {
            self.append(item)
        }
    }
  }
}


extension Array where Element: Equatable {

    //// Remove first collection element that is equal to the given `object`:
    mutating func removeItem(_ object : Element) {
        guard let index = firstIndex(of: object) else {return}
        remove(at: index)
    }
    
    func intersects(_ other: Array) -> Bool{
        for e in other {
            if contains(where: {$0 == e}) {
                return true
            }
        }
        return false
    }
}


