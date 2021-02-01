//
//  SignalR.swift
//  signalR
//
//  Created by Ayon Das on 23/07/20.
//

import Foundation

enum CallMethod : String {
  case connectToServer, reconnect, stop, invokeServerMethod, listenToHubMethod
}

class SignalR1Wrapper {

  static let instance = SignalR1Wrapper()
  private var hub: Hub!
  private var connection: SignalR1!

  func connectToServer(baseUrl: String, hubName: String, transport: Int, queryString : String, headers: [String: String], hubMethods: [String], result: @escaping FlutterResult) {
    connection = SignalR1(baseUrl)

    if !queryString.isEmpty {
      let qs = queryString.components(separatedBy: "=")
      connection.queryString = [qs[0]:qs[1]]
    }

    if transport == 1 {
      connection.transport = Transport.serverSentEvents
    } else if transport == 2 {
      connection.transport = Transport.longPolling
    }

    if headers.count > 0 {
      connection.headers = headers
    }

    hub = connection.createHubProxy(hubName)

    hubMethods.forEach { (methodName) in
      hub.on(methodName) { (args) in
        SwiftSignalRFlutterPlugin.channel.invokeMethod("NewMessage", arguments: [methodName, args?[0]])
      }
    }

    connection.starting = { [weak self] in
      print("SignalR1 Connecting. Current Status: \(String(describing: self?.connection.state.stringValue))")
      SwiftSignalRFlutterPlugin.channel.invokeMethod("ConnectionStatus", arguments: self?.connection.state.stringValue)
    }

    connection.reconnecting = { [weak self] in
      print("SignalR1 Reconnecting. Current Status: \(String(describing: self?.connection.state.stringValue))")
      SwiftSignalRFlutterPlugin.channel.invokeMethod("ConnectionStatus", arguments: self?.connection.state.stringValue)
    }

    connection.connected = { [weak self] in
      print("SignalR1 Connected. Connection ID: \(String(describing: self?.connection.connectionID))")
      SwiftSignalRFlutterPlugin.channel.invokeMethod("ConnectionStatus", arguments: self?.connection.state.stringValue)
    }

    connection.reconnected = { [weak self] in
      print("SignalR1 Reconnected...")
      print("Connection ID: \(String(describing: self?.connection.connectionID))")
      SwiftSignalRFlutterPlugin.channel.invokeMethod("ConnectionStatus", arguments: self?.connection.state.stringValue)
    }

    connection.disconnected = { [weak self] in
      print("SignalR1 Disconnected...")
      SwiftSignalRFlutterPlugin.channel.invokeMethod("ConnectionStatus", arguments: self?.connection.state.stringValue)
    }

    connection.connectionSlow = {
      print("Connection slow...")
      SwiftSignalRFlutterPlugin.channel.invokeMethod("ConnectionStatus", arguments: "Slow")
    }

    connection.error = { [weak self] error in
      print("Error: \(String(describing: error))")
      SwiftSignalRFlutterPlugin.channel.invokeMethod("ConnectionStatus", arguments: self?.connection.state.stringValue)

      if let source = error?["source"] as? String, source == "TimeoutException" {
        print("Connection timed out. Restarting...")
        self?.connection.start()
      }
    }

    connection.start()
    result(true)
  }

  func reconnect(result: @escaping FlutterResult) {
    if let connection = self.connection {
      connection.connect()
    } else {
      result(FlutterError(code: "Error", message: "SignalR1 Connection not found or null", details: "Start SignalR1 connection first"))
    }
  }

  func stop(result: @escaping FlutterResult) {
    if let connection = self.connection {
      connection.stop()
    } else {
      result(FlutterError(code: "Error", message: "SignalR1 Connection not found or null", details: "Start SignalR1 connection first"))
    }
  }

  func listenToHubMethod(methodName : String, result: @escaping FlutterResult) {
    if let hub = self.hub {
      hub.on(methodName) { (args) in
        SwiftSignalRFlutterPlugin.channel.invokeMethod("NewMessage", arguments: [methodName, args?[0]])
      }
    } else {
      result(FlutterError(code: "Error", message: "SignalR1 Connection not found or null", details: "Connect SignalR1 before listening a Hub method"))
    }
  }

  func invokeServerMethod(methodName: String, arguments: [Any]? = nil, result: @escaping FlutterResult) {
    do {
      if let hub = self.hub {
        try hub.invoke(methodName, arguments: arguments, callback: { (res, error) in
          if let error = error {
            result(FlutterError(code: "Error", message: String(describing: error), details: nil))
          } else {
            result(res)
          }
        })
      } else {
        throw NSError.init(domain: "NullPointerException", code: 0, userInfo: [NSLocalizedDescriptionKey : "Hub is null. Initiate a connection first."])
      }
    } catch {
      result(FlutterError.init(code: "Error", message: error.localizedDescription, details: nil))
    }
  }
}

