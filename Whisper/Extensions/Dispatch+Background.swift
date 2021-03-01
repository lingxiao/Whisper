//
//  Dispatch+Background.swift
//  byte
//
//  Created by: https://stackoverflow.com/questions/24056205/how-to-use-background-thread-in-swift
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation


typealias Dispatch = DispatchQueue

extension Dispatch {

    static func main(_ task: @escaping () -> ()) {
        Dispatch.main.async {
            task()
        }
    }

    static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }

}
