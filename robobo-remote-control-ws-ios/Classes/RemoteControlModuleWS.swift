//
//  RemoteControlModuleWS.swift
//  PocketSocket
//
//  Created by Luis on 30/05/2019.
//

import UIKit
import robobo_framework_ios_pod
import robobo_remote_control_ios
import PocketSocket

public class RemoteControlModuleWS: NSObject, IModule,  IRemoteControlProxy{
    var server: PSWebSocketServer! = nil;
    var manager: RoboboManager!
    var remote: IRemoteControlModule!
    var encoder: RoboboJSONEncoder!
    
    var connections: [Int:PSWebSocket]!

    public func notifyStatus(_ status: Status) {
        for (key,ws) in connections{
            ws.send(encoder.encodeStatus(status))
        }
    }
    
    public func notifyResponse(_ response: Response) {
        
    }
    
    public func startup(_ manager: RoboboManager) throws {
        
        connections = [:]
        
        do{
            
            var module = try manager.getModuleInstance("IRemoteControlModule")
            remote = module as? IRemoteControlModule
            
           
            
        }catch{
            print(error)
        }
        encoder = RoboboJSONEncoder()
        server = PSWebSocketServer(host: nil, port: 40404);
        self.manager = manager
        server.delegate = self
        server.start()
        remote.registerRemoteControlProxy(self)
    }
    
    public func shutdown() throws {
        
    }
    
    public func getModuleInfo() -> String {
        return "Robobo Websocket Module"
    }
    
    public func getModuleVersion() -> String {
        return "0.1.0"
    }
    

}

extension RemoteControlModuleWS: PSWebSocketServerDelegate{
    public func serverDidStop(_ server: PSWebSocketServer!) {
        print("serverDidStop")
    }
    
    public func serverDidStart(_ server: PSWebSocketServer!) {
        print("serverDidStart")
    }
    
    public func server(_ server: PSWebSocketServer!, didFailWithError error: Error!) {
        print("didFailWithError")
    }
    
    public func server(_ server: PSWebSocketServer!, webSocketDidOpen webSocket: PSWebSocket!) {
        connections[webSocket.hashValue] = webSocket
        remote.notifyConnection(connections.count)
        
        print("webSocketDidOpen")
    }
    
    public func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didReceiveMessage message: Any!) {
        //print("-------------------")
        //print(message as! String)
        
        var m:String = message as! String
        do{
        let command:RemoteCommand = try encoder.decodeCommand(CommandSanitizer.sanitize(m))
        remote.queueCommand(command)
        } catch {
            print(error)
        }
        //print("-------------------")

    }
    
    public func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didFailWithError error: Error!) {
        connections.removeValue(forKey: webSocket.hashValue)
        remote.notifyDisconnection(connections.count)

        print("didFailWithError error:\(error)")
    }
    
    public func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        connections.removeValue(forKey: webSocket.hashValue)
        remote.notifyDisconnection(connections.count)

        print("didCloseWithCode code:\(code) wasClean \(wasClean)")
    }
    
    
}
