//
//  ViewController.swift
//  AgoraTask
//
//  Created by Ahmet Ali ÇETİN on 3.04.2023.
//

import UIKit
import AVFoundation
import AgoraRtcKit

class ViewController: UIViewController {
    
    //MARK: OUTLETS
    var joinButton: UIButton!
    
    //MARK: PROPERTIES
    var joined: Bool = true {
        didSet {
            DispatchQueue.main.async {
                self.joinButton.setTitle(self.joined ? "Join" : "Leave", for: .normal)
            }
        }
    }
    
    ///GEREKLİ DEĞERLERİ CONSTANT İÇERİSİNDEN DEĞİŞTİRMEYİ UNUTMA
    // The main entry point for Video SDK
    var agoraEngine: AgoraRtcEngineKit!

    // By default, set the current user role to broadcaster to both send and receive streams.
    var userRole: AgoraClientRole = .broadcaster
    
    // Update with the App ID of your project generated on Agora Console.
    let appID: String = Constant.Keyword.appID

    // Update with the temporary token generated in Agora Console.
    var token: String = Constant.Keyword.token

    // Update with the channel name you used to generate the token in Agora Console.
    var channelName: String = Constant.Keyword.channelName
    

    
    
    
    //MARK: LIFECYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        initializeAgoraEngine()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        leaveChannel()
        DispatchQueue.global(qos: .userInitiated).async {
            AgoraRtcEngineKit.destroy()
        }
    }
    
 
    private func joinChannel() async -> Void {
        if await !self.checkForPermissions() {
            showStatusMessage(title: "Error", message: "Permissions were not granted")
            return
        }
        
        let option = AgoraRtcChannelMediaOptions()
        
        if self.userRole == .broadcaster {
            option.clientRoleType = .broadcaster
        }
        else {
            option.clientRoleType = .audience
        }
        
        ///FOR AN AUDIO CALL SCENARIO SET THE CHANNEL PROFILE AS COMMUNICATION
        
        option.channelProfile = .communication
        
        ///JOIN THE CHANNEL WITH THE TEMPORARY TOKEN AND THE CHANNEL NAME
        let result = agoraEngine.joinChannel(byToken: token, channelId: channelName, uid: 0, mediaOptions: option) { channel, uid, elapsed in
            print("channel: \(channel)")
            print("UID: \(uid)")
            print("elapsed: \(elapsed)")
        }
        
        // Check if joining the channel was successful and set joined Bool accordingly
        if result == 0 {
            joined = true
            showStatusMessage(title: "Success", message: "Successfully joined the \(self.channelName) channel as \(self.userRole)")
        }
        
    }
    
    private func leaveChannel() {
        let result = agoraEngine.leaveChannel(nil)
        // Check if leaving the channel was successful and set joined Bool accordingly
        if result == 0 { joined = false }
    }
    
    
    //MARK: AUTHORIZATON AND PERMISSON STATUS
    
    private func checkForPermissions() async -> Bool {
        let hasPermissions = await self.avAuthorization(mediaType: .audio)
        return hasPermissions
    }
    
    private func avAuthorization(mediaType: AVMediaType) async -> Bool {
        let mediaAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        
        switch mediaAuthorizationStatus {
        case .restricted, .denied:
            return false
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation({ contination in
                AVCaptureDevice.requestAccess(for: mediaType) { request in
                    contination.resume(returning: request)
                }
            })
        @unknown default:
            return false
        }
    }
    
    //MARK: AUTHORIZATIONS STATUS IS SHOWING WITH THE ALERT
    
    private func showStatusMessage(title: String?, message: String?, delay: Int = 2) -> Void {
        let deadlineTime = DispatchTime.now() + .seconds(delay)
        
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            self.present(alert, animated: true)
            alert.dismiss(animated: true, completion: nil)
        })
        
    }
    
    //MARK: INITIALIZE AGORA ENGINE
    
    private func initializeAgoraEngine() {
        let configuration = AgoraRtcEngineConfig()
        //Pass in your APPID here
        configuration.appId = appID
        
        //Use AgoraRtcEngineDelegate for the following delegate parameter.
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: configuration, delegate: self)
        
    }
    
    //MARK: UI CONFIGURATIONS
    
    private func setUI() {
        joinButton = UIButton(type: .system)
        joinButton.setTitle("Join", for: .normal)
        joinButton.frame = CGRect(x: 141, y: 700, width: 150, height: 100)
        joinButton.setTitleColor(.white, for: .normal)
        joinButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        joinButton.layer.cornerRadius = 10
        joinButton.backgroundColor = .systemIndigo
        
        joinButton.addTarget(self, action: #selector(joinButtonTapped), for: .touchUpInside)
        
        self.view.addSubview(joinButton)
    }
    
    //MARK: ACTION
    
    @objc private func joinButtonTapped(_ sender: UIButton) {
        
        joined.toggle()
        
        if !joined { //joined == true
            sender.isEnabled = false
            Task {
                
                await joinChannel()
                sender.isEnabled = true
            }
            
            
        } else {
            leaveChannel()
        }
    }
}

extension ViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("extension of didJoinedOfUID")
    }
}
