//
//  ExtensionVC+SFSpeechRecognizer.swift
//  AgoraTask
//
//  Created by Ahmet Ali ÇETİN on 9.04.2023.
//

import Foundation
import Speech

extension ViewController: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
         if available {
             self.joinButton.isEnabled = true
         } else {
             self.joinButton.isEnabled = false
         }
     }
}
