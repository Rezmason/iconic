//
//  IconSource.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

protocol IconSource {
  func supplyIcon(notWithin iconSet: IconSet) async -> Icon?
}
