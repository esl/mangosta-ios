//
//  AsyncOperation.swift
//  AsyncOperation
//
//  Created by Andres on 9/9/15.
//  Copyright (c) 2015 Andres Canal. All rights reserved.
//

import UIKit

public class AsyncOperation: NSOperation {
	enum State {
		case Ready
		case Executing
		case Finished
		
		func asKeyPath() -> String {
			switch self {
			case .Ready:
				return "isReady"
			case .Executing:
				return "isExecuting"
			case .Finished:
				return "isFinished"
			}
		}
	}
	
	var state = State.Ready {
		willSet {
			willChangeValueForKey(newValue.asKeyPath())
			willChangeValueForKey(state.asKeyPath())
		}
		
		didSet {
			didChangeValueForKey(oldValue.asKeyPath())
			didChangeValueForKey(state.asKeyPath())
		}
	}
	
	override public var ready: Bool {
		return state == .Ready
	}
	
	override public var executing: Bool {
		return state == .Executing
	}
	
	override public var finished: Bool {
		return state == .Finished
	}
	
	override public var asynchronous: Bool {
		return true
	}
	
	override init() {
		super.init()
	}
	
	final override public func start() {
		state = .Executing
		
		if self.cancelled {
			state = .Finished
		}
		
		self.execute()
	}
	
	public func execute(){
		// override
		
		finish()
	}
	
	public func finish(){
		state = .Finished
	}
}