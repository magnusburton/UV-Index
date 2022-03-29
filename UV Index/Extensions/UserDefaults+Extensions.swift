//
//  UserDefaults+Extensions.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-14.
//

import Foundation

extension UserDefaults {
	/// Retrieves a Codable object from UserDefaults.
	///
	/// - Parameters:
	///   - type: Class that conforms to the Codable protocol.
	///   - key: Identifier of the object.
	///   - decoder: Custom JSONDecoder instance. Defaults to `JSONDecoder()`.
	/// - Returns: Codable object for key (if exists).
	func object<T: Codable>(_ type: T.Type, with key: String, usingDecoder decoder: JSONDecoder = JSONDecoder()) -> T? {
		guard let data = value(forKey: key) as? Data else { return nil }
		return try? decoder.decode(type.self, from: data)
	}
	
	/// Allows storing of Codable objects to UserDefaults.
	///
	/// - Parameters:
	///   - object: Codable object to store.
	///   - key: Identifier of the object.
	///   - encoder: Custom JSONEncoder instance. Defaults to `JSONEncoder()`.
	func set<T: Codable>(object: T, forKey key: String, usingEncoder encoder: JSONEncoder = JSONEncoder()) {
		let data = try? encoder.encode(object)
		set(data, forKey: key)
	}
}
