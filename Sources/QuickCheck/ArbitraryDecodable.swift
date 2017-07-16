import Foundation
import LCG
import Prelude

let genInt8 = choose(Int(Int8.min)..<Int(Int8.max)).map(Int8.init)
let genInt16 = choose(Int(Int16.min)..<Int(Int16.max)).map(Int16.init)
let genInt32 = genInt.map(Int32.init)
let genInt64 = genInt.map(Int64.init)
let genUInt = choose(0..<2_000_000).map(UInt.init)
let genUInt8 = choose(0..<Int(UInt8.max)).map(UInt8.init)
let genUInt16 = choose(0..<Int(UInt16.max)).map(UInt16.init)
let genUInt32 = choose(0..<2_000_000).map(UInt32.init)
let genUInt64 = choose(0..<2_000_000).map(UInt64.init)
let genFloat = genDouble.map(Float.init)

private final class ArbitraryDecoder: Decoder {
  var genState: GenState
  var codingPath: [CodingKey] = []
  let userInfo: [CodingUserInfoKey: Any] = [:]

  init(seed: Seed, size: Int) {
    self.genState = (seed, size)
  }

  func run<T>(_ gen: Gen<T>) -> T {
    let (result, genState) = gen.run(self.genState)
    self.genState = genState
    return result
  }

  func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
    return .init(KeyedContainer(decoder: self))
  }

  func unkeyedContainer() throws -> UnkeyedDecodingContainer {
    return UnkeyedContainer(decoder: self)
  }

  func singleValueContainer() throws -> SingleValueDecodingContainer {
    return SingleValueContainer(decoder: self)
  }

  struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let allKeys: [Key]
    let codingPath: [CodingKey]
    let decoder: ArbitraryDecoder

    init(decoder: ArbitraryDecoder) {
      let genKeys = arrayOf(genInt.map(Key.init(intValue:)))
        |> scale { $0 * 2 }
        |> suchThat <| { $0.count % 2 == 0 }

      self.allKeys = decoder.run(genKeys).flatMap { $0 }
      self.codingPath = decoder.codingPath
      self.decoder = decoder
    }

    func contains(_ key: Key) -> Bool {
      return true
    }

    func decodeNil(forKey key: Key) throws -> Bool {
      return self.decoder.run(uniform.map { $0 >= 0.75 })
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
      self.decoder.codingPath.append(key)
      defer { self.decoder.codingPath.removeLast() }
      return try T(from: self.decoder)
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws
      -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        return .init(KeyedContainer<NestedKey>(decoder: self.decoder))
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
      self.decoder.codingPath.append(key)
      defer { self.decoder.codingPath.removeLast() }
      return UnkeyedContainer(decoder: self.decoder)
    }

    func superDecoder() throws -> Decoder {
      return self.decoder
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
      self.decoder.codingPath.append(key)
      defer { self.decoder.codingPath.removeLast() }
      return self.decoder
    }
  }

  struct UnkeyedContainer: UnkeyedDecodingContainer {
    let codingPath: [CodingKey]
    let count: Int?
    var currentIndex = 0
    let decoder: ArbitraryDecoder
    var isAtEnd: Bool { return currentIndex == count }

    init(decoder: ArbitraryDecoder) {
      self.codingPath = decoder.codingPath
      print(decoder.genState.size)
      self.count = decoder.run(choose(0..<decoder.genState.size) |> suchThat <| { $0 % 2 == 0 })
      self.decoder = decoder
    }

    func decodeNil() throws -> Bool {
      return self.decoder.run(uniform.map { $0 >= 0.75 })
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
      return try T(from: self.decoder)
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws
      -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        return .init(KeyedContainer<NestedKey>(decoder: self.decoder))
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
      return self
    }

    mutating func superDecoder() throws -> Decoder {
      defer { self.currentIndex += 1 }
      return self.decoder
    }
  }

  struct SingleValueContainer: SingleValueDecodingContainer {
    let codingPath: [CodingKey]
    let decoder: ArbitraryDecoder

    init(decoder: ArbitraryDecoder) {
      self.codingPath = decoder.codingPath
      self.decoder = decoder
    }

    func decodeNil() -> Bool {
      return self.decoder.run(uniform.map { $0 >= 0.75 })
    }

    func decode(_ type: Bool.Type) throws -> Bool {
      return self.decoder.run(genBool)
    }

    func decode(_ type: Int.Type) throws -> Int {
      return self.decoder.run(genInt)
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
      return self.decoder.run(genInt8)
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
      return self.decoder.run(genInt16)
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
      return self.decoder.run(genInt32)
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
      return self.decoder.run(genInt64)
    }

    func decode(_ type: UInt.Type) throws -> UInt {
      return self.decoder.run(genUInt)
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
      return self.decoder.run(genUInt8)
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
      return self.decoder.run(genUInt16)
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
      return self.decoder.run(genUInt32)
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
      return self.decoder.run(genUInt64)
    }

    func decode(_ type: Float.Type) throws -> Float {
      return self.decoder.run(genFloat)
    }

    func decode(_ type: Double.Type) throws -> Double {
      return self.decoder.run(genDouble)
    }

    func decode(_ type: String.Type) throws -> String {
      return self.decoder.run(genString)
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
      return try T(from: self.decoder)
    }
  }
}

extension Decodable {
  public static var gen: Gen<Self> {
    return Gen { state in
      let decoder = ArbitraryDecoder(seed: state.newSeed, size: state.size)
      let result = try! Self.init(from: decoder)
      return (result, decoder.genState)
    }
  }

  public static func arbitrary(seed: Seed = Seed.random.perform(), size: Int = 10) -> Self {
    return Self.gen.eval((seed, size))
  }
}
