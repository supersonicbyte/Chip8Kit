//
//  Bitmap.swift
//  chip8
//
//  Created by Mirza Ucanbarlic on 3. 4. 2022..
//

import Foundation

public struct Bitmap {
    public private(set) var pixels: [Color]
    public let width: Int
    
    public init(width: Int, pixels: [Color]) {
        self.width = width
        self.pixels = pixels
    }
}

public extension Bitmap {
    var height: Int {
        return pixels.count / width
    }
    
    subscript(x: Int, y: Int) -> Color {
        get { return pixels[y * width + x] }
        set { pixels[y * width + x] = newValue }
    }
    
    subscript(x: Int) -> Color {
        get { return pixels[x] }
        set { pixels[x] = newValue }
    }

    init(width: Int, height: Int, color: Color) {
        self.pixels = Array(repeating: color, count: width * height)
        self.width = width
    }
}

public extension Bitmap {
    init(buffer: [UInt32], width: Int) {
        self.pixels = Array(repeating: .white, count: buffer.count)
        self.width = width
        for (idx, pixel) in buffer.enumerated() {
            if pixel > 0 {
                pixels[idx] = .black
            }
        }
    }
}
