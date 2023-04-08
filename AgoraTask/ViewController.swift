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
import InstantSearchVoiceOverlay
import FirebaseAuth
import FirebaseDatabase


class ViewController: UIViewController {
    
    //MARK: OUTLETS
    var joinButton: UIButton!
    
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var speechToTextLabel: UILabel!
    @IBOutlet var exitFirebase: UIBarButtonItem!
    @IBOutlet var sendMessageTextField: UITextField!
    
    
    var messagesArray: [MessageModel] = []
    
    
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
    
    let voiceOverlayController = VoiceOverlayController()
    var textToSend: String = ""
    
    //MARK: TEXT TO SPEECH PROPERTIES
    let synthesizer = AVSpeechSynthesizer()
    
    var localUid: UInt = 0
    var remoteUid: UInt = 0
    
    let configuration = AgoraRtcEngineConfig()
    
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
        
        //Pass in your APPID here
        configuration.appId = appID
        print("kanala katılım başarılı oldu.")
        
        //Use AgoraRtcEngineDelegate for the following delegate parameter.
        agoraEngineConfigurations()
    }
    
    private func agoraEngineConfigurations() {
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: configuration, delegate: self)
        agoraEngine.setDefaultAudioRouteToSpeakerphone(true)
        agoraEngine.setEnableSpeakerphone(true)
        agoraEngine.setAudioProfile(.speechStandard)
        agoraEngine.enableLocalAudio(true)
        agoraEngine.startPreview()
        agoraEngine.adjustRecordingSignalVolume(12)
        agoraEngine.setChannelProfile(.communication)
        agoraEngine.enableDualStreamMode(true)
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

        self.view.addSubview(joinButton)
        joinButton.addTarget(self, action: #selector(joinButtonTapped), for: .touchUpInside)
        
        getMessages()
    }
    
    
    
    //MARK: ACTION
    
    @IBAction func exitFirebaseButtonTapped(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
            self.navigationController?.popViewController(animated: true)
        } catch {
            print("exit firebase error \(error.localizedDescription)")
        }
    }
    
    @IBAction func sendMessageButtonTapped(_ sender: UIButton) {
        sendMessageTextField.endEditing(true)
        sendMessageTextField.isEnabled = false
        
        let messageDatabase = Database.database().reference().child("Messages")
        let messageDictionary = ["Sender": Auth.auth().currentUser?.email, "Message body": sendMessageTextField.text!]
        messageDatabase.childByAutoId().setValue(messageDictionary) { error, databaseReference in
            if error != nil {
                print("Message saving error: \(String(describing: error?.localizedDescription))")
            } else {
                print("Message Saved Successfully")
                print(messageDictionary.isEmpty)
                self.messageLabel.text = self.sendMessageTextField.text
                self.sendMessageTextField.text = ""
                self.sendMessageTextField.isEnabled = true
            }
        }
        
    }
    
    private func getMessages() {
        let messageDatabase = Database.database().reference().child("Messages")
        
        messageDatabase.observe(.childAdded) { snapshot in
            let value = snapshot.value as! Dictionary<String, String>
            
            let text = value["Message body"]!
            let sender = value["Sender"]!
            print(text)
            print(sender)
            let message = MessageModel()
            message.messageBody = text
            message.sender = sender
            
            self.messagesArray.append(message)
            for array in self.messagesArray {
                self.messageLabel.text = array.messageBody.lowercased()
                print(array.messageBody)
            }
            
            self.textToSpeech(text: text)
            print(value.count)
            print("Message Array Count: \(self.messagesArray.count)")
            
        }
    }
    
    func textToSpeech(text: String) {
        DispatchQueue.main.async {
            self.speechToTextLabel.text = text
            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = 0.52
            utterance.voice = AVSpeechSynthesisVoice(language: Constant.SpeechIDs.Language.english)
            self.synthesizer.speak(utterance)
        }
    }
    
    @objc private func joinButtonTapped(_ sender: UIButton) {
        joined.toggle()
        
        if !joined { //joined == true
            sender.isEnabled = false
            Task {
                //MARK: Bu kısım sesle alakalı
                voiceOverlayController.start(on: self, textHandler: { text, isFinal, _ in
                    //self.speechToTextLabel.text = ""
                    if isFinal  {
                        self.speechToTextLabel.text = text
                        self.textToSend = text
                        print(self.textToSend)
                    } else {
                        print("Work in progress \(text)")
                        self.speechToTextLabel.text = text
                        print(text)
                    }
                }, errorHandler: { error in
                    print("errora girdi")
                    print("\(String(describing: error?.localizedDescription))")
                })
                self.speechToTextLabel.text = ""
                //: Bu kısım sesle alakalı
                
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
        self.agoraEngine.adjustAudioMixingVolume(12)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        self.agoraEngine.adjustAudioMixingVolume(12)
    }
    
    ///MESAJ ALINDIĞINDA YAPILACAKLAR
    func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
        if uid == localUid {
            return
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print(errorCode.rawValue.codingKey)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        print("didLeaveChannelWithStats")
        agoraEngine.stopPreview()
    }
}

extension ViewController: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
         if available {
             self.joinButton.isEnabled = true
         } else {
             self.joinButton.isEnabled = false
         }
     }
}

