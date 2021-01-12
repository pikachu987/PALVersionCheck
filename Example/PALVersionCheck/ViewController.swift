//
//  ViewController.swift
//  PALVersionCheck
//
//  Created by pikachu987 on 01/12/2021.
//  Copyright (c) 2021 pikachu987. All rights reserved.
//

import UIKit
import PALVersionCheck

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        AppStore.versionCheck { (version) in
            print(version)
        }
        
        AppStore.versionCheck("com.~~~.~~~~") { (version) in
            print(version)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

