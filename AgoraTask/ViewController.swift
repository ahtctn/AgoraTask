//
//  ViewController.swift
//  AgoraTask
//
//  Created by Ahmet Ali ÇETİN on 3.04.2023.
//

import UIKit
import AVFoundation
import AgoraRtcKit
import Speech
import AVKit

class ViewController: UIViewController {
    
    //MARK: OUTLETS
    var joinButton: UIButton!
    
    var talkButton: UIButton!
    var listenButton: UIButton!
    
    var speechToTextLabel: UILabel!
    
    //MARK: AGORA PROPERTIES
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
    let appID: String = Constant.AgoraIDs.appID

    // Update with the temporary token generated in Agora Console.
    var token: String = Constant.AgoraIDs.token

    // Update with the channel name you used to generate the token in Agora Console.
    var channelName: String = Constant.AgoraIDs.channelName
    
    //MARK: SPEECH TO TEXT PROPERTIES
    
    //MARK: TEXT TO SPEECH PROPERTIES
    let synthesizer = AVSpeechSynthesizer()
    
    
    //MARK: SPEECH TO TEXT PROPERTIES
    
    
    
    
    //MARK: LIFECYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        initializeAgoraEngine()
        //self.setupSpeech()
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
            
            let successAlert = UIAlertController(title: "Successfull", message: "GİRİŞ YAPILDI", preferredStyle: .alert)
            self.present(successAlert, animated: true)
            successAlert.dismiss(animated: true)
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
        joinButton.frame = CGRect(x: 141, y: 750, width: 150, height: 100)
        joinButton.setTitleColor(.white, for: .normal)
        joinButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        joinButton.layer.cornerRadius = 10
        joinButton.backgroundColor = .systemIndigo
        
        joinButton.addTarget(self, action: #selector(joinButtonTapped), for: .touchUpInside)
        
        speechToTextLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        speechToTextLabel.textAlignment = .center
        speechToTextLabel.center = CGPoint(x: 220, y: 300)
        speechToTextLabel.textColor = .white
        speechToTextLabel.font = UIFont.boldSystemFont(ofSize: 20)
        speechToTextLabel.backgroundColor = .systemIndigo
        speechToTextLabel.numberOfLines = 20
        speechToTextLabel.layer.cornerRadius = 20
        ///Buraya speech'den gelen içerik konulacak.
        //speechToTextLabel.text = "Hello guys, It's Steve here, I am exciting for this task. I hope i will work with Articula family."
        speechToTextLabel.text = "Merhaba arkadaşlar, ben Ahmet. Bu görev ve Articula'da çalışıp dolar kazanma ihtimalimden dolayı oldukça heyecanlı hissediyorum."
        
        
        talkButton = UIButton(type: .system)
        talkButton.setTitle("Talk 🔊", for: .normal)
        talkButton.frame = CGRect(x: 141, y: 625, width: 150, height: 100)
        talkButton.setTitleColor(.white, for: .normal)
        talkButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        talkButton.layer.cornerRadius = 10
        talkButton.backgroundColor = .systemIndigo
        
        talkButton.addTarget(self, action: #selector(talkButtonTapped), for: .touchUpInside)
        
        listenButton = UIButton(type: .system)
        listenButton.setTitle("Listen 🎵", for: .normal)
        listenButton.frame = CGRect(x: 141, y: 500, width: 150, height: 100)
        listenButton.setTitleColor(.white, for: .normal)
        listenButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        listenButton.layer.cornerRadius = 10
        listenButton.backgroundColor = .systemIndigo
        
        listenButton.addTarget(self, action: #selector(listenButtonTapped), for: .touchUpInside)
        
        
        
        self.view.addSubview(speechToTextLabel)

        self.view.addSubview(joinButton)
        self.view.addSubview(talkButton)
        self.view.addSubview(listenButton)
    }
    
    //MARK: SPEECH TO TEXT FUNCTIONS
    
   
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
    
    @objc private func talkButtonTapped(_ sender: UIButton) {
        let utterance = AVSpeechUtterance(string: speechToTextLabel.text ?? "no text to talk")
        utterance.rate = 0.52
        utterance.voice = AVSpeechSynthesisVoice(language: Constant.SpeechIDs.Language.english)
        synthesizer.speak(utterance)
        print("talk button tapped")
         
    }
    
    @objc private func listenButtonTapped(_ sender: UIButton) {

    }
}

extension ViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("extension of didJoinedOfUID")
    }
}

extension ViewController: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
         if available {
             self.listenButton.isEnabled = true
         } else {
             self.listenButton.isEnabled = false
         }
     }
    
}
