//
//  ExtensionVC+RTCEngine.swift
//  AgoraTask
//
//  Created by Ahmet Ali ÇETİN on 9.04.2023.
//

import Foundation
import AgoraRtcKit
import InstantSearchVoiceOverlay

extension AgoraCommunicationViewController: AgoraRtcEngineDelegate {
    
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


extension AgoraCommunicationViewController: VoiceOverlayDelegate {
    func recording(text: String?, final: Bool?, error: Error?) {
        print(text)
    }
}
