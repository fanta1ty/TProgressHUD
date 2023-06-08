//
//  ViewController.swift
//  TProgressHUD
//
//  Created by thinhnguyen12389 on 06/08/2023.
//  Copyright (c) 2023 thinhnguyen12389. All rights reserved.
//

import UIKit
import TProgressHUD

class ViewController: UIViewController {
    private var activityCount = 0
    private var progress = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityCount = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleNotification(notification:)),
            name: Notification.Name(TProgressHUDWillAppearNotification),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleNotification(notification:)),
            name: Notification.Name(TProgressHUDDidAppearNotification),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleNotification(notification:)),
            name: Notification.Name(TProgressHUDWillDisappearNotification),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleNotification(notification:)),
            name: Notification.Name(TProgressHUDDidDisappearNotification),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleNotification(notification:)),
            name: Notification.Name(TProgressHUDDidReceiveTouchEventNotification),
            object: nil
        )
        
        addObserver(
            self,
            forKeyPath: "activityCount",
            options: .new,
            context: nil
        )
    }
    
    @IBAction func onShowBtn(_ sender: Any) {
        TProgressHUD.show()
        activityCount += 1
    }
    @IBAction func showWithStatus(_ sender: Any) {
        TProgressHUD.showWithStatus(status: "Doing Stuff")
        activityCount += 1
    }
    @IBAction func showSuccessWithStatus(_ sender: Any) {
        TProgressHUD.showSuccessWithStatus(status: "Great Success!")
        activityCount += 1
    }
    @IBAction func showInfoWithStatus(_ sender: Any) {
        TProgressHUD.showInfoWithStatus(status: "Useful Information.")
        activityCount += 1
    }
    @IBAction func showErrorWithStatus(_ sender: Any) {
        TProgressHUD.showErrorWithStatus(status: "Failed with Error")
        activityCount += 1
    }
    @IBAction func onDismiss(_ sender: Any) {
        TProgressHUD.dismiss()
        activityCount = 0
    }
    
    @objc
    private func handleNotification(notification: Notification) {
        if notification.name.rawValue == TProgressHUDDidReceiveTouchEventNotification {
            onDismiss(notification)
        }
    }
}

