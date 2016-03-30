//
//  Result.swift
//  MongooseIM
//
//  Created by Tom Ryan on 2/29/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation

public enum Result<A> {
	case Success(Box<A>)
	case Error(ErrorType)
}

public final class Box<T> {
	let value: T
	init(_ value: T) {
		self.value = value
	}
}