//
//  StringExtension.swift
//  alpha
//
//  Created by Xiao Ling on 4/15/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit

// Extension to test string and optional string emptiness: https://useyourloaf.com/blog/empty-strings-in-swift/
func isBlank(_ string: String) -> Bool {
  for character in string {
    if !character.isWhitespace {
        return false
    }
  }
  return true
}

extension String {
  var isBlank: Bool {
    return allSatisfy({ $0.isWhitespace })
  }
}

extension Optional where Wrapped == String {
  var isBlank: Bool {
    return self?.isBlank ?? true
  }
}


extension String {
    /// This method makes it easier extract a substring by character index where a character is viewed as a human-readable character (grapheme cluster).
    internal func substring(start: Int, offsetBy: Int) -> String? {
        guard let substringStartIndex = self.index(startIndex, offsetBy: start, limitedBy: endIndex) else {
            return nil
        }

        guard let substringEndIndex = self.index(startIndex, offsetBy: start + offsetBy, limitedBy: endIndex) else {
            return nil
        }

        return String(self[substringStartIndex ..< substringEndIndex])
    }
}


