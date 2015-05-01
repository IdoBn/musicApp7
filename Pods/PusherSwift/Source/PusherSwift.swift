//
//  PusherSwift.swift
//
//  Created by Hamilton Chapman on 19/02/2015.
//
//

import Foundation
import Alamofire
import SwiftyJSON
import Starscream

public class Pusher {
    let connection: PusherConnection
    let PROTOCOL = 7
    let VERSION = "0.0.1"
    let authEndpoint: String?

    public init(key: String, encrypted: Bool = false, authEndpoint: String? = nil) {
        self.authEndpoint = authEndpoint
        var url = ""
        if encrypted {
            url = "wss://ws.pusherapp.com:443/app/\(key)"
        } else {
            url = "ws://ws.pusherapp.com:80/app/\(key)"
        }

        url += "?client=pusher-swift&version=\(VERSION)&protocol=\(PROTOCOL)"
        connection = PusherConnection(url: url, authEndpoint: self.authEndpoint)
    }

    public func subscribe(channelName: String) -> PusherChannel {
        return self.connection.addChannel(channelName)
    }

    public func disconnect() {
        self.connection.close()
    }

    public func connect() {
        self.connection.open()
    }

    //    func bind(event_name, &callback) {
    //        global_channel.bind(event_name, &callback)
    //        return self
    //    }
}

public class PusherConnection: WebSocketDelegate {
    let url: String
    let authEndpoint: String?
    var socketId: String?
    lazy var socket: WebSocket = { [unowned self] in
        return self.connectInternal()
        }()
    var connected = false
    var channels = PusherChannels()

    init(url: String, authEndpoint: String?) {
        self.url = url
        self.authEndpoint = authEndpoint
        self.socket = self.connectInternal()
    }

    private func addChannel(channelName: String) -> PusherChannel {
        var newChannel = channels.add(channelName, connection: self)
        if self.connected {
            self.authorize(newChannel)
        }
        return newChannel
    }

    private func sendEvent(event: String, data: AnyObject, channelName: String? = nil) {
        if event.componentsSeparatedByString("-")[0] == "client" {
            sendClientEvent(event, data: data, channelName: channelName)
        } else {
            self.socket.writeString(JSONStringify(["event": event, "data": data]))
        }
    }

    private func sendClientEvent(event: String, data: AnyObject, channelName: String?) {
        if let cName = channelName {
            if isPresenceChannel(cName) || isPrivateChannel(cName) {
                self.socket.writeString(JSONStringify(["event": event, "data": data, "channel": cName]))
            } else {
                println("You must be subscribed to a private or presence channel to send client events")
            }
        }
    }

    private func JSONStringify(value: AnyObject) -> String {
        if NSJSONSerialization.isValidJSONObject(value) {
            if let data = NSJSONSerialization.dataWithJSONObject(value, options: nil, error: nil) {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string as String
                }
            }
        }
        return ""
    }

    private func close() {
        if self.connected {
            self.socket.disconnect()
        }
    }

    private func open() {
        if self.connected {
            return
        } else {
            self.socket = connectInternal()
        }
    }

    private func connectInternal() -> WebSocket {
        let ws = WebSocket(url: NSURL(string: self.url)!)
        ws.delegate = self
        ws.connect()
        return ws
    }

    private func handleSubscriptionSucceededEvent(json: JSON) {
        if let channelName = json["channel"].string {
            if let chan = self.channels.find(channelName) {
                chan.subscribed = true
                if isPresenceChannel(channelName) {
                    if let presChan = self.channels.find(channelName) as? PresencePusherChannel {
                        if let data = json["data"].string {
                            let dataJSON = getJSONFromString(data)

                            if let members = dataJSON["presence"]["hash"].dictionary {
                                println(members)
                                presChan.members = members
                            }
                        }
                    }
                }
                for (eventName, data) in chan.unsentEvents {
                    chan.unsentEvents.removeValueForKey(channelName)
                    chan.trigger(eventName, data: data)
                }
            }
        }
    }

    private func handleConnectionEstablishedEvent(json: JSON) {
        if let data = json["data"].string {
            let connectionData = getJSONFromString(data)

            if let socketId = connectionData["socket_id"].string {
                self.connected = true
                self.socketId = socketId

                for (channelName, channel) in self.channels.channels {
                    if !channel.subscribed {
                        self.authorize(channel)
                    }
                }
            }
        }
    }

    private func handleMemberAddedEvent(json: JSON) {
        if let data = json["data"].string {
            let memberJSON = getJSONFromString(data)

            if let channelName = json["channel"].string {
                if let chan = self.channels.find(channelName) as? PresencePusherChannel {
                    chan.addMember(memberJSON)
                }
            }
        }
    }

    private func handleMemberRemovedEvent(json: JSON) {
        if let data = json["data"].string {
            let memberJSON = getJSONFromString(data)

            if let channelName = json["channel"].string {
                if let chan = self.channels.find(channelName) as? PresencePusherChannel {
                    chan.removeMember(memberJSON)
                }
            }
        }
    }

    private func getJSONFromString(string: String) -> JSON {
        let data = (string as NSString).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        return JSON(data: data!)
    }

    private func handleEvent(eventName: String, json: JSON) {
        switch eventName {
        case "pusher_internal:subscription_succeeded":
            handleSubscriptionSucceededEvent(json)
        case "pusher:connection_established":
            handleConnectionEstablishedEvent(json)
        case "pusher_internal:member_added":
            handleMemberAddedEvent(json)
        case "pusher_internal:member_removed":
            handleMemberRemovedEvent(json)
        default:
            if let channelName = json["channel"].string {
                if let internalChannel = self.channels.find(channelName) {
                    if let eName = json["event"].string {
                        if let eData = json["data"].string {
                            internalChannel.handleEvent(eName, eventData: eData)
                        }
                    }
                }
            }
        }
    }

    private func authorize(channel: PusherChannel, callback: ((Dictionary<String, String>?) -> Void)? = nil) {
        if !isPresenceChannel(channel.name) && !isPrivateChannel(channel.name) {
            subscribeToNormalChannel(channel)
        }
        if let endpoint = self.authEndpoint {
            let url: NSURL = NSURL(string: endpoint)!
            if let socket = self.socketId {
                sendAuthorisationRequest(url, socket: socket, channel: channel, callback: callback)
            } else {
                println("socketId value not found")
            }
        } else {
            println("authEndpoint not set")
        }
    }

    private func subscribeToNormalChannel(channel: PusherChannel) {
        self.sendEvent("pusher:subscribe",
            data: [
                "channel": channel.name
            ]
        )
    }

    private func sendAuthorisationRequest(url: NSURL, socket: String, channel: PusherChannel, callback: ((Dictionary<String, String>?) -> Void)? = nil) {
        Alamofire.request(.POST, url, parameters: ["socket_id": socket, "channel_name": channel.name])
            .responseJSON { (_, _, jsonResponse, error) in
                if let err = error {
                    println("Error authorizing channel: \(err)")
                } else if let json = jsonResponse as? Dictionary<String, AnyObject> {
                    self.handleAuthResponse(json, channel: channel, callback: callback)
                }
        }
    }

    private func handleAuthResponse(json: Dictionary<String, AnyObject>, channel: PusherChannel, callback: ((Dictionary<String, String>?) -> Void)? = nil) {
        if let auth = json["auth"] as? String {
            if let channelData = json["channel_data"] as? String {
                handlePresenceChannelAuth(auth, channel: channel, channelData: channelData, callback: callback)
            } else {
                handlePrivateChannelAuth(auth, channel: channel, callback: callback)
            }
        }
    }

    private func handlePresenceChannelAuth(auth: String, channel: PusherChannel, channelData: String, callback: ((Dictionary<String, String>?) -> Void)? = nil) {
        if let cBack = callback {
            cBack(["auth": auth, "channel_data": channelData])
        } else {
            self.sendEvent("pusher:subscribe",
                data: [
                    "channel": channel.name,
                    "auth": auth,
                    "channel_data": channelData
                ]
            )
        }
    }

    private func handlePrivateChannelAuth(auth: String, channel: PusherChannel, callback: ((Dictionary<String, String>?) -> Void)? = nil) {
        if let cBack = callback {
            cBack(["auth": auth])
        } else {
            self.sendEvent("pusher:subscribe",
                data: [
                    "channel": channel.name,
                    "auth": auth
                ]
            )
        }
    }

    // MARK: WebSocketDelegate Implementation

    public func websocketDidReceiveMessage(ws: WebSocket, text: String) {
        let data = (text as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        let json = JSON(data: data!)

        if let eventName = json["event"].string {
            self.handleEvent(eventName, json: json)
        }
    }

    public func websocketDidConnect(ws: WebSocket) {
        println("*******************************************")
        println("Connected")
        println("*******************************************")
    }

    public func websocketDidDisconnect(ws: WebSocket, error: NSError?) {
        println("——————————————")
        println("Websocket is disconnected: \(error!.localizedDescription)")
        println("——————————————")
        self.connected = false
        for (channelName, channel) in self.channels.channels {
            channel.subscribed = false
        }
        var timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: Selector("testTimer"), userInfo: nil, repeats: true)
    }

    func testTimer() {
        println("Looking for connection")
    }

    public func websocketDidReceiveData(ws: WebSocket, data: NSData) {
    }
}

public class PusherChannel {
    var callbacks: [String: (JSON) -> Void]
    var subscribed = false
    let name: String
    let connection: PusherConnection
    var unsentEvents = [String: AnyObject?]()
    var userData: AnyObject? = nil

    init(name: String, connection: PusherConnection) {
        self.name = name
        self.connection = connection
        self.callbacks = [:]
    }

    public func bind(eventName: String, callback: (JSON) -> Void) {
        self.callbacks[eventName] = callback
    }

    private func handleEvent(eventName: String, eventData: String) {
        if let cb = self.callbacks[eventName] {
            let data = (eventData as NSString).dataUsingEncoding(NSUTF8StringEncoding)
            let json = JSON(data: data!)
            cb(json)
        }
    }

    public func trigger(eventName: String, data: AnyObject?) {
        if subscribed {
            if let d = data as? Dictionary<String, AnyObject> {
                self.connection.sendEvent(eventName, data: d, channelName: self.name)
            } else {
                println("Your data is all messed up")
            }
        } else {
            unsentEvents[eventName] = data
        }
    }
}

public class PresencePusherChannel: PusherChannel {
    var members: Dictionary<String, JSON>

    override init(name: String, connection: PusherConnection) {
        self.members = [:]
        super.init(name: name, connection: connection)
    }

    private func addMember(memberJSON: JSON) {
        let userInfo: AnyObject = memberJSON["user_info"].object

        if let userId = memberJSON["user_id"].string {
            self.members[userId] = JSON(self.connection.JSONStringify(userInfo))
        } else if let userId = memberJSON["user_id"].int {
            self.members[String(userId)] = JSON(self.connection.JSONStringify(userInfo))
        }
    }

    private func removeMember(memberJSON: JSON) {
        if let userId = memberJSON["user_id"].string {
            self.members.removeValueForKey(userId)
        } else if let userId = memberJSON["user_id"].int {
            self.members.removeValueForKey(String(userId))
        }
    }
}

class Members {
    //TODO: Consider setting up Members object for Presence Channels
}

public class PusherChannels {
    var channels = [String: PusherChannel]()

    private func add(channelName: String, connection: PusherConnection) -> PusherChannel {
        if let channel = self.channels[channelName] {
            return channel
        } else {
            var newChannel: PusherChannel
            if isPresenceChannel(channelName) {
                newChannel = PresencePusherChannel(name: channelName, connection: connection)
            } else {
                newChannel = PusherChannel(name: channelName, connection: connection)
            }
            self.channels[channelName] = newChannel
            return newChannel
        }
    }

    private func remove(channelName: String) {
        self.channels.removeValueForKey(channelName)
    }

    private func find(channelName: String) -> PusherChannel? {
        return self.channels[channelName]
    }
}

private func isPresenceChannel(channelName: String) -> Bool {
    return (channelName.componentsSeparatedByString("-")[0] == "presence") ? true : false
}

private func isPrivateChannel(channelName: String) -> Bool {
    return (channelName.componentsSeparatedByString("-")[0] == "private") ? true : false
}