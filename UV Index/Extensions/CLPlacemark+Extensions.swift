//
//  CLPlacemark+Extensions.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-28.
//

import Foundation
import CoreLocation
import Algorithms

extension CLPlacemark {
	var formatted: String? {
		let attributes: [String?] = [
			self.name,
			self.subAdministrativeArea,
			self.administrativeArea
		]
		
		var cleanedAttributes = attributes.uniqued().compactMap({ $0 })
		
		// Add country if only one attribute including name
		if cleanedAttributes.count <= 1, let country = self.country {
			cleanedAttributes.append(country)
			cleanedAttributes = cleanedAttributes.uniqued().map({ $0 })
		}
		
		if cleanedAttributes.isEmpty {
			return nil
		}
		
		return cleanedAttributes.joined(separator: ", ")
	}
	
	var formattedSubtitle: String? {
		let attributes: [String?] = [
			self.name,
			self.subAdministrativeArea,
			self.administrativeArea
		]
		
		var cleanedAttributes = attributes.uniqued().compactMap({ $0 })
		
		// Remove duplicates if subtitle includes name as well
		if let name = self.name, cleanedAttributes.contains(name) {
			
			cleanedAttributes.removeAll(where: { $0 == name })
			
		} else if cleanedAttributes.count == 0, let country = self.country {
			// Add country if no attributes
			cleanedAttributes.append(country)
			
		}
		
		if cleanedAttributes.isEmpty {
			return nil
		}
		
		return cleanedAttributes.joined(separator: ", ")
	}
}
