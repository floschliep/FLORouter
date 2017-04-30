//
//  ViewController.swift
//  Demo
//
//  Created by Florian Schliep on 28.04.17.
//  Copyright © 2017 Florian Schliep. All rights reserved.
//

import Cocoa
import FLORouter

class ViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Router.global.register("test") { [weak self] _ in
            guard let window = self?.view.window else { return false }
            let alert = NSAlert()
            alert.messageText = "Received URL!"
            alert.beginSheetModal(for: window, completionHandler: nil)
            
            return true
        }
    }

    @IBAction func openURL(_ sender: Any) {
        NSWorkspace.shared().open(URL(string: "florouter-sample://test")!)
    }
    
}

