//
//  LocationError.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-07.
//

import SwiftUI

enum LocationError: Error {
	case noData
	case noModel
	case noPermission
	
	case unknown(error: Error)
}

extension LocationError: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .noData:
			return NSLocalizedString("Missing valid data.", comment: "")
		case .noModel:
			return NSLocalizedString("Missing valid data model.", comment: "")
		case .noPermission:
			return NSLocalizedString("Insufficient permissions.", comment: "")
		case .unknown(let error):
			return NSLocalizedString("Received unexpected error. \(error.localizedDescription)", comment: "")
		}
	}
}

extension LocationError: Identifiable {
	var id: String? {
		errorDescription
	}
}
