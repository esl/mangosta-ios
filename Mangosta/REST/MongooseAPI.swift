//
//  MongooseAPI.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework


extension NSURLSessionBackend {
	class func MongooseREST() -> NSURLSessionBackend {
		let basePath = "https://31.172.186.62:5285/api/"
		
		let authModel = AuthenticationModel.load()
		let username = authModel?.jid.bare()
		let password = authModel?.password
		
		let token = username! + ":" + password!.toBase64()

		let headers = [HTTPHeader(field: "Accept", value: "application/json"),
		               HTTPHeader(field: "Content-Type", value: "application/json"),
		               HTTPHeader(field: "Authorization", value: "Basic" + token)]
		
		let configuration = NSURLSessionBackendConfiguration(basePath: basePath, httpHeaders: headers)
		return NSURLSessionBackend(configuration: configuration)
	}
}

extension MongooseAPI: LoginControllerDelegate {
	func didLogIn() {
		self.xmppController = self.referenceForXMPPController()
	}
}

extension String {
	/**
	Encode a String to Base64
	
	:returns:
	*/
	func toBase64()->String{
		
		let data = self.dataUsingEncoding(NSUTF8StringEncoding)
		
		return data!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
		
	}
	
}

class MongooseAPI: NSObject {
	
	static let RESPONSE_OK = 204
	static let NOT_FOUND = 404
	
	weak var xmppController: XMPPController!
	
	let backend = NSURLSessionBackend.MongooseREST()
	
	
	
	private	func referenceForXMPPController() -> XMPPController {
	
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		return appDelegate.xmppController
		
	}
}