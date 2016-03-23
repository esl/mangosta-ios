//
//  AsyncOperation.swift
//  MongooseIM
//
//  Created by Tom Ryan on 2/29/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation

public class AsyncOperation : NSOperation {
	enum State : String {
		case Ready
		case Executing
		case Finished
	}
	var state = State.Ready {
		willSet {
			self.willChangeValueForKey(newValue.rawValue)
			self.willChangeValueForKey(state.rawValue)
		}
		
		didSet {
			self.didChangeValueForKey(oldValue.rawValue)
			self.didChangeValueForKey(state.rawValue)
		}
	}
	
	override public var ready : Bool {
		return self.state == .Ready
	}
	
	override public var executing : Bool {
		return self.state == .Executing
	}
	
	override public var finished : Bool {
		return self.state == .Finished
	}
	
	override public var asynchronous : Bool {
		return true
	}
	
	override init() {
		super.init()
	}
	
	final override public func start() {
		self.state = .Executing
		
		if self.cancelled {
			self.state = .Finished
		}
		
		self.execute()
	}
	
	public func execute() {
		self.finish()
	}
	
	public func finish() {
		self.state = .Finished
	}
}