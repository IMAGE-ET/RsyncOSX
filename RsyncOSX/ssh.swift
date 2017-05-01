//
//  ssh.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 23.04.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//


import Foundation
import Cocoa

class ssh: files {
    
    // Delegate for reporting file error if any to main view
    // Comply to protocol
    weak var error_delegate: ReportErrorInMain?
    
    let rsa:String = "id_rsa.pub"
    let dsa:String = "id_dsa.pub"
    var dsaPubKey:Bool = false
    var rsaPubKey:Bool = false
    
    // Full paths to public keys
    var rsaURLpath:URL?
    var dsaURLpath:URL?
    var rsaStringPath:String?
    var dasStringPath:String?
    
    var fileURLS:Array<URL>?
    var fileStrings:Array<String>?
    
    var scpArguments:scpArgumentsSsh?
    var command:String?
    var arguments:Array<String>?
    
    // Process
    var process:commandSsh?
    var output:outputProcess?
    
    
    // Create Keys
    
    func creatKeysRsa(hiddenID:Int) {
        self.scpArguments = scpArgumentsSsh(hiddenID: hiddenID)
        self.arguments = scpArguments!.getArguments(operation: .createKey, key: "rsa", path: nil)
        self.command = self.scpArguments!.getCommand()
        self.executeSshCommand()
    }
    
    func createKeysDsa(hiddenID:Int) {
        self.scpArguments = scpArgumentsSsh(hiddenID: hiddenID)
        self.arguments = scpArguments!.getArguments(operation: .createKey, key: "dsa", path: nil)
        self.command = self.scpArguments!.getCommand()
        self.executeSshCommand()
    }
    
    // Check for keys
    func checkKeys() {
        self.rsaPubKey = self.existPubKeys(key: rsa)
        self.dsaPubKey = self.existPubKeys(key: dsa)
    }
    
    // Check if rsa and/or dsa is existing in local .ssh catalog
    func existPubKeys (key:String) -> Bool {
        guard self.fileStrings != nil else {
            return false
        }
        guard self.fileStrings!.filter({$0.contains(key)}).count == 1 else {
            return false
        }
        switch key {
        case self.rsa:
            self.rsaURLpath = URL(string: self.fileStrings!.filter({$0.contains(key)})[0])
            self.rsaStringPath = self.fileStrings!.filter({$0.contains(key)})[0]
        case self.dsa:
            self.dsaURLpath = URL(string: self.fileStrings!.filter({$0.contains(key)})[0])
            self.dasStringPath = self.fileStrings!.filter({$0.contains(key)})[0]
        default:
            break
        }
        return true
    }
    
    // Secure copy of public key from local to remote catalog
    func ScpPubKey(key: String, hiddenID:Int) {
        self.scpArguments = scpArgumentsSsh(hiddenID: hiddenID)
        switch key {
        case "rsa":
            guard self.rsaStringPath != nil else {
                return
            }
            self.arguments = scpArguments!.getArguments(operation: .scpKey, key: key, path: self.rsaStringPath!)
        case "dsa":
            guard self.dasStringPath != nil else {
                return
            }
            self.arguments = scpArguments!.getArguments(operation: .scpKey, key: key, path: self.dasStringPath!)
        default:
            break
        }
        self.command = self.scpArguments!.getCommand()
    }
    
    // Check for remote pub keys
    func checkRemotePubKey(key: String, hiddenID:Int) {
        self.scpArguments = scpArgumentsSsh(hiddenID: hiddenID)
        switch key {
        case "rsa":
            guard self.rsaStringPath != nil else {
                return
            }
            self.arguments = scpArguments!.getArguments(operation: .checkKey, key: key, path: nil)
        case "dsa":
            guard self.dasStringPath != nil else {
                return
            }
            self.arguments = scpArguments!.getArguments(operation: .checkKey, key: key, path: nil)
        default:
            break
        }
        self.command = self.scpArguments!.getCommand()
    }
    
    
    // Check if public key is present remote
    func executeSshCommand() {
        self.process = commandSsh(command: self.command, arguments: self.arguments)
        self.output = outputProcess()
        self.process!.executeProcess(output: self.output!)
    }
    
    // get output
    func getOutput() -> Array<String> {
        return self.output!.getOutput()
    }
    
    init() {
        super.init(path: nil, root: .userRoot)
        self.fileURLS = self.getFilesURLs()
        self.fileStrings = self.getFileStrings()
        self.checkKeys()
    }
    
}

extension ssh: ReportError {
    // Private func for propagating any file error to main view
    func reportError(errorstr:String) {
        if let pvc = SharingManagerConfiguration.sharedInstance.ViewControllertabMain {
            self.error_delegate = pvc as? ViewControllertabMain
            self.error_delegate?.fileerror(errorstr: errorstr)
        }
    }
    
}
