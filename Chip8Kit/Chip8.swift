//
//  Chip8.swift
//  chip8
//
//  Created by Mirza Ucanbarlic on 26. 3. 2022..
//

import Foundation

extension UInt16 {
    func printAsHex() -> String {
        return String(self, radix: 16)
    }
}

fileprivate enum Chip8Error: Error {
    case dataToLarge
}

fileprivate struct Stack<T> {
    private var array: [T]
    
    func top() -> T? {
        return array.last
    }
    
    mutating func push(_ newElement: T) {
        array.append(newElement)
    }
    
    mutating func pop() -> T? {
        return array.popLast()
    }
    
    init() {
        array = []
    }
}
typealias Byte = UInt8
typealias Word = UInt16

public struct Chip8 {
    private struct Constants {
        static let videoWidth = 64
        static let videoHeight = 32
        static let startAddress = 0x200
        static let fontsetStartAddress = 0x50
    }
    private var registers = [Byte](repeating: 0, count: 16)
    private var memory = [Byte](repeating: 0, count: 4096)
    private var index: Word = 0
    private var pc: Word = Word(Constants.startAddress)
    private var stack = Stack<Word>()
    private var delayTimer: Byte = 0
    private var soundTimer: Byte = 0
    public var video = [UInt32](repeating: 0, count: 64 * 32)
    private var keypad = [Byte](repeating: 0, count: 16)
    private var opcode: Word = 0
    private let fontset: [Byte] = [
        0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
        0x20, 0x60, 0x20, 0x20, 0x70, // 1
        0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
        0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
        0x90, 0x90, 0xF0, 0x10, 0x10, // 4
        0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
        0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
        0xF0, 0x10, 0x20, 0x40, 0x40, // 7
        0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
        0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
        0xF0, 0x90, 0xF0, 0x90, 0x90, // A
        0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
        0xF0, 0x80, 0x80, 0x80, 0xF0, // C
        0xE0, 0x90, 0x90, 0x90, 0xE0, // D
        0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
        0xF0, 0x80, 0xF0, 0x80, 0x80  // F
    ]
    
    var vx: Int {
        return Int((opcode & 0x0F00) >> 8)
    }
    var vy: Int {
        return Int((opcode & 0x00F0) >> 4)

    }
    var byte: Byte {
        return Byte(opcode & 0x00FF)
    }
    var address: Word {
        return opcode & 0x0FFF
    }
    
    public init() {
        for i in fontset.startIndex ..< fontset.endIndex {
            memory[Constants.fontsetStartAddress + i] = fontset[i]
        }
    }
    
    public mutating func reset() {
        for i in 0..<registers.count {
            registers[i] = 0
        }
        for i in 0..<memory.count {
            memory[i] = 0
        }
        pc = Word(Constants.startAddress)
        stack = Stack<Word>()
        delayTimer = 0
        soundTimer = 0
        for i in 0..<video.count {
            video[i] = 0
        }
        for i in 0..<keypad.count {
            keypad[i] = 0
        }
    }
    
    public mutating func loadROM(from data: Data) throws {
        if data.count > memory.count - Constants.startAddress {
            throw Chip8Error.dataToLarge
        }
        for i in 0 ..< data.count {
            memory[Constants.startAddress + i] = data[i]
        }
    }
    
    /// CLS
    /// Clear the display
    mutating func op00E0() {
        video = [UInt32](repeating: 0, count: Constants.videoHeight * Constants.videoWidth)
    }
    
    /// RET
    /// Return from a subroutine
    mutating func op00EE() {
        guard let top = stack.pop() else {
            fatalError()
        }
        pc = top
    }
    
    /// JP addr
    /// Jump to address nnn
    mutating func op1nnn() {
        pc = address
    }
    
    /// CALL addr
    /// Call subroutine at nnn
    mutating func op2nnn() {
        stack.push(pc)
        pc = address
    }
    
    /// SE vx, byte
    /// Skip next instruction if vx == kk
    mutating func op3xkk() {
        if registers[vx] == byte {
            pc += 2
        }
    }
    
    /// SNE vx, byte
    /// Skip next instruction if vx  != kk
    mutating func op4xkk() {
        if registers[vx] != byte {
            pc += 2
        }
    }
    
    /// SE vx, vy
    /// Skip next instruction if vx == vy
    mutating func op5xy0() {
        if registers[vx] == registers[vy] {
            pc += 2
        }
    }
    
    // LD vx, byte
    /// Set vx = kk
    mutating func op6xkk() {
        registers[vx] = byte
    }
    
    /// ADD vx, byte
    /// Set vx = vx + kk
    mutating func op7xkk() {
        registers[vx] = registers[vx] &+ byte
    }
    
    /// LD vx, vy
    /// Set vx = vy
    mutating func op8xy0() {
        registers[vx] = registers[vy]
    }
    
    /// OR vx, vy
    /// Set vx  = vx OR vy
    mutating func op8xy1() {
        registers[vx] = registers[vx] | registers[vy]
    }
    
    /// AND vx, vy
    /// Set vx = vx AND vy
    mutating func op8xy2() {
        registers[vx] = registers[vx] & registers[vy]
    }
    
    /// XOR vx, vy
    /// Set vx = vx XOR vy
    mutating func op8xy3() {
        registers[vx] = registers[vx] ^ registers[vy]
    }
    
    /// ADD vx, vy
    /// Set vx  = vx + vy, set vf = carry
    mutating func op8xy4() {
        let sum: UInt16 = UInt16(Int(registers[vx]) + Int(registers[vy]))
        if sum > UInt16(255) {
            registers[0xF] = 1
        } else {
            registers[0xF] = 0
        }
        registers[vx] = UInt8(sum & 0xFF)
    }
    
    /// SUB vx, vy
    /// Set vx = vx - vy, set vf = NOT borrow
    mutating func op8xy5() {
        if registers[vx] > registers[vy] {
            registers[0xF] = 1
        } else {
            registers[0xF] = 0
        }
        registers[vx] = registers[vx] &- registers[vy]
    }
    
    /// SHR vx
    /// Set vx = vx shr 1
    /// If the least-significant bit of Vx is 1, then VF is set to 1, otherwise 0. Then Vx is divided by 2.
    mutating func op8xy6() {
        registers[0xF] = (registers[vx] & 0x1)
        registers[vx] = registers[vx] >> 1
    }
    
    /// SUBN vx, vy
    /// Set vx = vy - vx, set VF = NOT borrow
    mutating func op8xy7() {
        if registers[vy] > registers[vx] {
            registers[0xF] = 1
        } else {
            registers[0xF] = 0
        }
       registers[vx] = registers[vy] &- registers[vx]
    }
    
    /// SHL vx
    /// Set vx = vx SHL 1.
    /// If the most-significant bit of vx is 1, then vf is set to 1, otherwise to 0. Then vx is multiplied by 2.
    mutating func op8xyE() {
        registers[0xF] = (registers[vx] & 0x80 >> 7)
        registers[vx] = registers[vx] << 1
    }
    
    /// SNE vx, vy
    /// Skip next instruction if vx != vy
    mutating func op9xy0() {
        if registers[vx] != registers[vy] {
            pc += 2
        }
    }
    
    /// LD I, addr
    /// Set I = nnn
    mutating func opAnnn() {
        index = address
    }
    
    /// JP v0, addr
    /// Jumpt o location nnn + v0
    mutating func opBnnn() {
        pc = Word(registers[0]) + address
    }
    /// RND vx, byte
    /// Set vx = random byte AND kk
    mutating func opCxkk() {
        registers[vx] = UInt8.random(in: 0..<225) & byte
    }
    
    /// DRW vx, vy, nibble
    /// Display n-byte sprite starting at memory location I at (vx, vy), set vf = collision
    /// We iterate over the sprite, row by row and column by column. We know there are eight columns because a sprite is guaranteed to be eight pixels wide.
    /// If a sprite pixel is on then there may be a collision with what’s already being displayed, so we check if our screen pixel in the same location is set. If so we must set the VF register to express collision.
    /// Then we can just XOR the screen pixel with 0xFFFFFFFF to essentially XOR it with the sprite pixel (which we now know is on). We can’t XOR directly because the sprite pixel is either 1 or 0 while our video pixel is either 0x00000000 or 0xFFFFFFFF.
    mutating func opDxyn() {
        let height: Byte = Byte(opcode & 0x000F)
        
        let xPos = registers[vx] % Byte(Constants.videoWidth)
        let yPos = registers[vy] % Byte(Constants.videoHeight)
        
        registers[0xF] = 0
        
        for row in 0..<height {
            let spriteByte: UInt8 = memory[Int(index + UInt16(row))]
            for col in 0..<8 {
                let spiritePixel = spriteByte & (0x80 >> col)
                let screenPixelIndex = Int(Int((yPos + row)) * Constants.videoWidth + Int((xPos + UInt8(col))))
                guard screenPixelIndex < video.count else { return }
                if spiritePixel != 0 {
                    if video[screenPixelIndex] == 0xFFFFFFFF {
                        registers[0xF] = 1
                    }
                    video[screenPixelIndex] = video[screenPixelIndex] ^ 0xFFFFFFFF
                }
            }
        }
    }
    
    /// SKP vx
    /// Skip next instruction if key with the value of vx is pressed
    mutating func opEx9E() {
        let key: UInt8 = registers[vx]
        if keypad[Int(key)] != 0 {
            pc += 2
        }
    }
    
    /// SKNP vx
    /// Skip next instruction if key with the value of vx is not pressed
    mutating func opExA1() {
        let key: UInt8 = registers[vx]
        if keypad[Int(key)] == 0 {
            pc += 2
        }
    }
    
    /// LD vx, DT
    /// Set vx = delay timer value
    mutating func opFx07() {
        registers[vx] = delayTimer
    }
    
    /// LD vx, K
    /// Wait for a key press, store the value fo the key in vx
    mutating func opFx0A() {
        guard let keypadIndex = keypad.firstIndex(where: { $0 == 1 }) else {
            pc -= 2
            return
        }
        registers[vx] = UInt8(keypadIndex)
    }
    
    /// LD DT, vx
    /// Set delay time = vx
    mutating func opFx15() {
        delayTimer = registers[vx]
    }
    
    /// LD ST, vx
    /// Set sound time = vx
    mutating func opFx18() {
        soundTimer = registers[vx]
    }
    
    /// ADD I, vx
    /// set i = i + vx
    mutating func opFx1E() {
        index += Word(registers[vx])
    }
    
    /// LD F, vx
    /// Set I = location of sprite for digit vx
    mutating func opFx29() {
        let digit: Byte = registers[vx]
        index = Word(Constants.fontsetStartAddress) + Word((5 * digit))
    }
    
    /// LD B, vx
    /// Store BCD representation of vx in memory locations I, I+1, and I+2
    mutating func opFx33() {
        var value: Byte = registers[vx]
        memory[Int(index) + 2] = value % 10
        value /= 10
        memory[Int(index) + 1] = value % 10
        value /= 10
        memory[Int(index)] = value % 10
    }
    
    /// LD [I], vx
    /// Store regisers v0 thorugh vx in memory starting at location I
    mutating func opFx55() {
        for i in 0...vx {
            memory[Int(index) + i] = registers[i]
        }
    }
    
    /// LD vx, [I]
    /// Read registers v0 through vx from memory starting at location I
    mutating func opFx65() {
        for i in 0...vx {
            registers[i] = memory[Int(index + UInt16(i))]
        }
    }
    
    public mutating func cycle() {
        opcode = (Word(memory[Int(pc)]) << 8) | (Word(memory[Int(pc) + 1]))
        pc += 2
                
        self.decode()
        
        if delayTimer > 0 {
            delayTimer -= 1
        }
        
        if soundTimer > 0 {
            soundTimer -= 1
        }
    }
    
    mutating func decode() {
        let nibble = (opcode & 0xF000) >> 12
        switch nibble {
        case 0x1:
            self.op1nnn()
        case 0x2:
            self.op2nnn()
        case 0x3:
            self.op3xkk()
        case 0x4:
            self.op4xkk()
        case 0x5:
            self.op5xy0()
        case 0x6:
            self.op6xkk()
        case 0x7:
            self.op7xkk()
        case 0x9:
            self.op9xy0()
        case 0xA:
            self.opAnnn()
        case 0xB:
            self.opBnnn()
        case 0xC:
            self.opCxkk()
        case 0xD:
            self.opDxyn()
        case 0x8:
            let lastDigit = opcode & 0x000F
            switch lastDigit {
            case 0x0:
                self.op8xy0()
            case 0x1:
                self.op8xy1()
            case 0x2:
                self.op8xy2()
            case 0x3:
                self.op8xy3()
            case 0x4:
                self.op8xy4()
            case 0x5:
                self.op8xy5()
            case 0x6:
                self.op8xy6()
            case 0x7:
                self.op8xy7()
            case 0xE:
                self.op8xyE()
            default:
                return
            }
        case 0x0:
            let twoLast = opcode & 0x00FF
            switch twoLast {
            case 0xE0:
                self.op00E0()
            case 0xEE:
                self.op00EE()
            default:
                return
            }
        case 0xE:
            let twoLast = opcode & 0x00FF
            switch twoLast {
            case 0xA1:
                self.opExA1()
            case 0x9E:
                self.opEx9E()
            default:
                return
            }
        case 0xF:
            let twoLast = opcode & 0x00FF
            switch twoLast {
            case 0x0A:
                self.opFx0A()
            case 0x07:
                self.opFx07()
            case 0x15:
                self.opFx15()
            case 0x18:
                self.opFx18()
            case 0x1E:
                self.opFx1E()
            case 0x29:
                self.opFx29()
            case 0x33:
                self.opFx33()
            case 0x55:
                self.opFx55()
            case 0x65:
                self.opFx65()
            default:
                return
            }
        default:
            return
        }
    }
}

public extension Chip8 {
    mutating func select(key: Int) {
        guard key >= 0, key < 16 else {
            fatalError("Wrong key!")
        }
        keypad[key] = 1
    }
    
    mutating func deselect(key: Int) {
        guard key >= 0, key < 16 else {
            fatalError("Wrong key!")
        }
        keypad[key] = 0
    }
}
