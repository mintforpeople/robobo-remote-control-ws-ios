//
//  CommandQueueProcessor.swift
//  robobo-remote-control
//
//  Created by Luis Felipe Llamas Luaces on 01/04/2019.
//  Copyright © 2019 mintforpeople. All rights reserved.
//

import robobo_framework_ios_pod
class CommandQueueProcessor: NSObject {
    var interrupted: Bool = false
    var commandQueue: CommandQueue!
    var remoteModule: IRemoteControlModule!
    var roboboManager :RoboboManager!
    var timer:Timer!
    var lastCommandReceptionTime:Int = 0
    let MAX_TIME_WITHOUT_COMMANDS_TO_SLEEP: Int = 60 * 3
    var commandExecutors: [String: ICommandExecutor]!

    
    var queue: DispatchQueue!

    
    public init(_ remote:IRemoteControlModule, _ roboboManager:RoboboManager) {
        self.remoteModule = remote
        self.roboboManager = roboboManager
        commandQueue = CommandQueue()
        commandExecutors = [:]
        super.init()
        

    }
    
    func start(){
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(MAX_TIME_WITHOUT_COMMANDS_TO_SLEEP), target: self, selector: #selector(CommandQueueProcessor.periodicCommandReceptionCheck), userInfo: nil, repeats: true)
        timer.fire()
        queue = DispatchQueue(label: "CommandQueueProcessor", qos: .userInteractive)
        queue.async {
            self.run()
        }
    }
    
    func run(){
        var i = 0
        while !interrupted {
            var command: Command! 
            i = i+1
            
            do {
                if (!commandQueue.isEmpty()){
                    //roboboManager.log("Command Queued")
                    
                    command = try commandQueue.take()
                    do{
                        let commandExecutor: ICommandExecutor = try getCommandExecutor(command.getName())
                        commandExecutor.executeCommand(command, remoteModule)
                        
                    } catch RemoteModuleError.commandExecutorNotFound{
                        roboboManager.log("Command executor for \(command.getName()) not found", LogLevel.ERROR)
                    } catch {
                        
                    }
                }
            } catch {
                
            }
            
        }
    }
    
    func registerCommand(_ commandName:String, _ module:ICommandExecutor){
        commandExecutors[commandName] = module
    }
    
    func dispose() {
        interrupted = true
    }
    
    func getCommandExecutor(_ commandName:String) throws -> ICommandExecutor {
        //FIXME Controlar que no exista el commandexecutor
        if commandExecutors.keys.contains(commandName){
            return  commandExecutors[commandName]!
            
        }else{
            throw RemoteModuleError.commandExecutorNotFound
        }
    }
    
    func put(_ command: Command) throws{
        if (interrupted){
            throw RemoteModuleError.commandCannotBeAdded
        }
        
        lastCommandReceptionTime = Date().millisecondsSince1970
        // roboboManager.changePowerModeTo(PowerMode.NORMAL)
        //roboboManager.log("Is empty? \(commandQueue.isEmpty())")
        commandQueue.put(command)
    }
    
    @objc func periodicCommandReceptionCheck(){
        
        if ((Date().millisecondsSince1970 - lastCommandReceptionTime) > MAX_TIME_WITHOUT_COMMANDS_TO_SLEEP){
            // TODO SLEEP MODE
        }
    }
    
    
    
    
    
    
}

extension Date {
    var millisecondsSince1970:Int {
        return Int((self.timeIntervalSince1970 * 1000.0).rounded())
    }

}
