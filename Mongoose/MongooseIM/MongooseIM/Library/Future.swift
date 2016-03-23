//
//  Future.swift
//  MongooseIM
//
//  Created by Tom Ryan on 2/29/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation

typealias ErrorHandler = (ErrorType) -> ()

public struct Future<T, E: ErrorType> {
	public typealias ResultType = Result<T>
	public typealias Completion = ResultType -> ()
	public typealias AsyncOperation = Completion -> ()
	
	private let operation : AsyncOperation
	
	public init(result: ResultType) {
		self.init(operation: { completion in
			completion(result)
		})
	}
	
	public init(value: T) {
		self.init(result: .Success(Box(value)))
	}
	
	public init(error: E) {
		self.init(result: .Error(error))
	}
	
	public init(operation: AsyncOperation) {
		self.operation = operation
	}
	
	func start(completion: Completion) {
		self.operation() { result in
			completion(result)
		}
	}
}