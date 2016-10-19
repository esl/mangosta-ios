//
//  MongooseAPI.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

class NSTrustedURLSessionBackendDelegate: NSObject, NSURLSessionDelegate {
		func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
			if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust{
				// print ("I will accept a self signed certificate")
				let credential = NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!)
				completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential,credential);
			}
		}
}

extension NSURLSessionBackend {
	class func MongooseREST() -> NSURLSessionBackend {
		let basePath = "https://31.172.186.62:5285/api/"
		
		let authModel = AuthenticationModel.load()
		let username = authModel?.jid.bare()
		let password = authModel?.password
		
		let token = username! + ":" + password!

		let headers = [HTTPHeader(field: "Accept", value: "application/json"),
		               HTTPHeader(field: "Content-Type", value: "application/json"),
		               HTTPHeader(field: "Authorization", value: "Basic " + token.toBase64())]
		
		let configuration = NSURLSessionBackendConfiguration(basePath: basePath, httpHeaders: headers)
		let delegate = NSTrustedURLSessionBackendDelegate()
		let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
		                           delegate: delegate,
		                           delegateQueue: NSOperationQueue()
		)
		return NSURLSessionBackend(configuration: configuration, session: session)
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
// swiftlint:disable variable_name
class MongooseAPI: NSObject {
	
	static let RESPONSE_OK = 204
	static let NOT_FOUND = 404
	
	weak var xmppController: XMPPController!
	
	let backend = NSURLSessionBackend.MongooseREST()
	
	let activateLogger = Logger()
	
	private	func referenceForXMPPController() -> XMPPController {
	
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		return appDelegate.xmppController
		
	}
}