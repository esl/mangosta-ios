//
//  MongooseAPI.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework
import Jayme

class NSTrustedURLSessionBackendDelegate: NSObject, URLSessionDelegate {
		func URLSession(_ session: Foundation.URLSession, task: URLSessionTask, didReceiveChallenge challenge: URLAuthenticationChallenge, completionHandler: (Foundation.URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
			if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
				// print ("I will accept a self signed certificate")
				let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
				completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, credential)
			}
		}
}

extension URLSessionBackend {
	class func MongooseREST() -> URLSessionBackend {
		let basePath = "https://31.172.186.62:5285/api/"
		
		let authModel = AuthenticationModel.load()
		let username = authModel?.jid.bare() as String!
		let password = authModel?.password
		
		let token = username! + ":" + password!

		let headers = [HTTPHeader(field: "Accept", value: "application/json"),
		               HTTPHeader(field: "Content-Type", value: "application/json"),
		               HTTPHeader(field: "Authorization", value: "Basic " + token.toBase64())]
		
		let configuration = URLSessionBackendConfiguration(basePath: basePath, httpHeaders: headers)
		let delegate = NSTrustedURLSessionBackendDelegate()
		let session = URLSession(configuration: URLSessionConfiguration.default,
		                           delegate: delegate,
		                           delegateQueue: OperationQueue()
		)
		return URLSessionBackend(configuration: configuration, session: session)
	}
}

extension String {
	/**
	Encode a String to Base64
	
	:returns:
	*/
	func toBase64() -> String {
		
		let data = self.data(using: String.Encoding.utf8)
		
		return data!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
		
	}
	
}
// swiftlint:disable variable_name
class MongooseAPI: NSObject {
	
	static let RESPONSE_OK = 204
	static let NOT_FOUND = 404
	
	weak var xmppController: XMPPController!
	
	let backend = URLSessionBackend.MongooseREST()
	
	let activateLogger = Logger.sharedLogger
	
	fileprivate	func referenceForXMPPController() -> XMPPController {
	
		return XMPPController.sharedInstance
		
	}
}
