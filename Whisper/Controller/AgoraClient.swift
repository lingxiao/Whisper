//
//  AgoraClient.swift
//  byte
//
//  Created by Xiao Ling on 11/8/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import AgoraRtcKit
import UIKit

//MARK:- delegate

protocol AgoraClientAppDelegate {
    func didJoinLocal   ( with tok: UInt ) -> Void
    func didJoinRemote  ( with tok: UInt ) -> Void
    func didLeave       ( with tok: UInt ) -> Void
    func volumeIndicator( from speakers: [UInt:UInt] ) -> Void
}


let CONFIG_DEV = AgoraVideoEncoderConfiguration(
      size: AgoraVideoDimension640x360
    , frameRate: .fps30
    , bitrate: AgoraVideoBitrateStandard
    , orientationMode: .adaptative
)

let CONFIG_PRODUCTION = AgoraVideoEncoderConfiguration(
      size: AgoraVideoDimension1280x720
    , frameRate: .fps60
    , bitrate: AgoraVideoBitrateStandard
    , orientationMode: .adaptative
)




//MARK:- class


/**
 @use: global agora instance:
    agoraKit.switchChannel(byToken: nil, channelId: channel.channelName, joinSuccess: nil)
    @Doc:  :https://docs.agora.io/cn/Voice/A, AgoraRtcEngineDelegatePI%20Reference/java/classio_1_1agora_1_1rtc_1_1_rtc_engine.html#af5f4de754e2c1f493096641c5c5c1d8f
    @DOC for VPN: https://docs.agora.io/en/Agora%20Platform/firewall?platform=All%20Platforms
    @Doc: https://github.com/AgoraIO/Basic-Audio-Call/blob/master/Group-Voice-Call/OpenVoiceCall-iOS/OpenVoiceCall/RoomViewController.swift
*/
class AgoraClient : NSObject {

    static let shared = AgoraClient()
    var delegate : AgoraClientAppDelegate?
    
    var agoraKit: AgoraRtcEngineKit?
    var currentChan: String?

    override init(){
        super.init()
        setAgoraKit()
    }
    
    public func setAgoraKit(){
      
        self.agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: AppID, delegate: self)
        agoraKit?.delegate = self
        agoraKit?.enableWebSdkInteroperability(true)

        // sample loudest speaker every second
        agoraKit?.enableAudioVolumeIndication(1000, smooth: 3, report_vad: true)

        agoraKit?.enableAudio()
        
        // config for livecast to start
        agoraKit?.setChannelProfile(.liveBroadcasting)
        
        // set framrate and HD/SD
        agoraKit?.setVideoEncoderConfiguration( CONFIG_PRODUCTION )
        
        //agoraKit?.setDefaultAudioRouteToSpeakerphone(true)
    }
    
    //MARK:- API    
    func inChannel() -> Bool {
        return self.currentChan != nil
    }
    
    //@use: exit agora channel
    func leaveChannel( _ then: @escaping() -> Void ){
        if self.currentChan == nil {
            return then()
        } else {
            UIApplication.shared.isIdleTimerDisabled = false
            //stopRecording()
            agoraKit?.leaveChannel(){_ in
                self.currentChan = nil
                then()
            }
        }
    }
    

    func startClubChannel( at uid: String?, host: Bool, _ then: @escaping(Bool) -> Void){
        guard let uid = uid else { return then(false) }
        joinChannel(at: uid, host: host){b in then(b) }
    }
        
    
    // @use: start channel
    func startChannel( _ then: @escaping(Bool) -> Void ){
        joinChannel(at: UserAuthed.shared.uuid, host: true){ b in then(b) }
    }
    
    // @use: Join channel
    func joinChannel( at uuid: String?, host: Bool, _ then: @escaping(Bool) -> Void ){
        guard let uuid = uuid else { return then(false ) }
        if uuid == "" { return then(false) }
        
        agoraKit?.enableAudio()
        agoraKit?.setClientRole( host ? .broadcaster : .audience )
        mute()
        
        if let curr_uuid  = self.currentChan {
            if curr_uuid == uuid {
                return then(true)
            } else {
                leaveChannel(){
                    self.currentChan = nil
                    self.goJoinChannel(at: uuid){ then(true) }
                }
            }
        } else {
            goJoinChannel(at: uuid ){ then(true) }
        }
    }
    
    func setAsHost(){
        agoraKit?.setClientRole( .broadcaster )
        unMute()
    }
    
    func setAsGuest(){ 
        agoraKit?.setClientRole( .audience )
        mute()
    }
    
    func mute(){
        agoraKit?.adjustPlaybackSignalVolume(100)
        agoraKit?.adjustRecordingSignalVolume(0)
    }

    func unMute(){
        agoraKit?.adjustPlaybackSignalVolume(100)
        agoraKit?.adjustRecordingSignalVolume(100)
    }
    
    func muteAudioAndPlayback(){
        agoraKit?.adjustPlaybackSignalVolume(0)
        agoraKit?.adjustRecordingSignalVolume(0)
    }
    
    func startRecording( to fp: String ){
        //let _ = agoraKit?.startAudioRecording(fp, quality: .high)
    }
    
    func stopRecording(){
        //let _ = agoraKit?.stopAudioRecording()
    }
    
    //MARK:- utils
    
    private func goJoinChannel( at uuid: String, _ then: @escaping() -> Void  ){
        setAgoraKit()
        agoraKit?.joinChannel(
            byToken: nil
          , channelId: uuid
          , info: UserAuthed.shared.uuid
          , uid: 0
        ) {(sid, uid, elapsed) in
            self.currentChan = uuid
            then()
            self.delegate?.didJoinLocal(with: uid)
        }
    }    
}


//MARK:- agora callback
 
extension AgoraClient: AgoraRtcEngineDelegate {
    
    /* Occurs when the connection between the SDK and the server is interrupted.
    *
    * **DEPRECATED** from v2.3.2. Use the [connectionChangedToState]([AgoraRtcEngineDelegate rtcEngine:connectionChangedToState:reason:]) callback instead.
    *
    * The SDK triggers this callback when it loses connection with the server for more than four seconds after a connection is established.
    *
    * This callback is different from [rtcEngineConnectionDidLost]([AgoraRtcEngineDelegate rtcEngineConnectionDidLost:]):
    *
    * - The SDK triggers this callback when it loses connection with the server for more than four seconds after it joins the channel.
    * - The SDK triggers the [rtcEngineConnectionDidLost when it loses connection with the server for more than 10 seconds, regardless of whether it joins the channel or not.
    *
    * If the SDK fails to rejoin the channel 20 minutes after being disconnected from Agora's edge server, the SDK stops rejoining the channel.
    *
    *  @param engine - AgoraRtcEngineKit object.
    */
    func rtcEngineConnectionDidInterrupted(_ engine: AgoraRtcEngineKit) {
        //print( "Connection Interrupted")
    }
    
    /* Occurs when the SDK cannot reconnect to Agora's edge server 10 seconds after its connection to the server is interrupted.
    *  See the description above to compare this method to rtcEngineConnectionDidInterrupted.
    *
    * @param engine AgoraRtcEngineKit object.
    */
    func rtcEngineConnectionDidLost(_ engine: AgoraRtcEngineKit) {
        //print( "Connection Lost")
    }
    
    /* Reports an error during SDK runtime.
    *
    * In most cases, the SDK cannot fix the issue and resume running. The SDK requires the app to take action or informs the user about the issue.
    *
    * For example, the SDK reports an AgoraErrorCodeStartCall = 1002 error when failing to initialize a call. The app informs the user that the call initialization failed and invokes the [leaveChannel]([AgoraRtcEngineKit leaveChannel:]) method to leave the channel.
    *
    *  @param engine   - AgoraRtcEngineKit object
    *  @param errorCode - Error code: AgoraErrorCode
    */
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        //print( "Occur error: \(errorCode.rawValue)")
    }
    
    /* This method handles event for the local user joins a specified channel.
    *
    *  @param engine  - AgoraRtcEngineKit object.
    *  @param channel - Channel name.
    *  @param uid     - User ID. If the `uid` is specified in the [joinChannelByToken]([AgoraRtcEngineKit joinChannelByToken:channelId:info:uid:joinSuccess:]) method, the specified user ID is returned. If the user ID is not specified when the joinChannel method is called, the server automatically assigns a `uid`.
    *  @param elapsed - Time elapsed (ms) from the user calling the [joinChannelByToken]([AgoraRtcEngineKit joinChannelByToken:channelId:info:uid:joinSuccess:]) method until the SDK triggers this callback.
    * - */
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        //print( "Did joined channel: \(channel), with uid: \(uid), elapsed: \(elapsed)")
    }
    
    /* This method handles event for a remote user or host joins a channel.
     * - Communication profile: This callback notifies the app that another user joins the channel. If other users are already in the channel, the SDK also reports to the app on the existing users.
     * - Live-broadcast profile: This callback notifies the app that a host joins the channel. If other hosts are already in the channel, the SDK also reports to the app on the existing hosts. Agora recommends limiting the number of hosts to 17.

     * The SDK triggers this callback under one of the following circumstances:
     * - A remote user/host joins the channel by calling the [joinChannelByToken]([AgoraRtcEngineKit joinChannelByToken:channelId:info:uid:joinSuccess:]) method.
     * - A remote user switches the user role to the host by calling the [setClientRole]([AgoraRtcEngineKit setClientRole:]) method after joining the channel.
     * - A remote user/host rejoins the channel after a network interruption.
     * - A host injects an online media stream into the channel by calling the [addInjectStreamUrl]([AgoraRtcEngineKit addInjectStreamUrl:config:]) method.

     * *Note:**

     * Live-broadcast profile:
     *
     * * The host receives this callback when another host joins the channel.
     * * The audience in the channel receives this callback when a new host joins the channel.
     * * When a web application joins the channel, the SDK triggers this callback as long as the web application publishes streams.
     *
     * @param engine  - AgoraRtcEngineKit object.
     * @param uid     - ID of the user or host who joins the channel. If the `uid` is specified in the [joinChannelByToken]([AgoraRtcEngineKit joinChannelByToken:channelId:info:uid:joinSuccess:]) method, the specified user ID is returned. If the `uid` is not specified in the joinChannelByToken method, the Agora server automatically assigns a `uid`.
     * @param elapsed - Time elapsed (ms) from the local user calling the [joinChannelByToken]([AgoraRtcEngineKit joinChannelByToken:channelId:info:uid:joinSuccess:]) or [setClientRole]([AgoraRtcEngineKit setClientRole:]) method until the SDK triggers this callback.
    */
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        //print( "Did joined of uid: \(uid)")
        delegate?.didJoinRemote(with: uid)
    }
    
    /* Occurs when a remote user (Communication)/host (Live Broadcast) leaves a channel. Same as [userOfflineBlock]([AgoraRtcEngineKit userOfflineBlock:]).
    *
    * There are two reasons for users to be offline:
    *
    * - Leave a channel: When the user/host leaves a channel, the user/host sends a goodbye message. When the message is received, the SDK assumes that the user/host leaves a channel.
    * - Drop offline: When no data packet of the user or host is received for a certain period of time (20 seconds for the Communication profile, and more for the Live-broadcast profile), the SDK assumes that the user/host drops offline. Unreliable network connections may lead to false detections, so Agora recommends using a signaling system for more reliable offline detection.
    *
    *  @param engine - AgoraRtcEngineKit object.
    *  @param uid   - ID o -f the user or host who leaves a channel or goes offline.
    *  @param reason - Reason why the user goes offline, see AgoraUserOfflineReason.
    */
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        //print( "Did offline of uid: \(uid), reason: \(reason.rawValue)")
        if reason.rawValue != 2 {
            delegate?.didLeave(with: uid)
        }
    }
    
    /* Reports the audio quality of the remote user.
    *
    *  @param engine  - AgoraRtcEngineKit object.
    *  @param uid     - User ID of the speaker.
    *  @param quality - Audio quality of the user, see [AgoraNetworkQuality](https://docs.agora.io/en/Voice/API%20Reference/oc/Constants/AgoraNetworkQuality.html).
    *  @param delay - Time delay (ms) of the audio packet sent from the sender to the receiver, including the time delay from audio sampling pre-processing, transmission, and the jitter buffer.
    *  @param lost - Packet loss rate (%) of the audio packet sent from the sender to the receiver.
    * - */
    func rtcEngine(_ engine: AgoraRtcEngineKit, audioQualityOfUid uid: UInt, quality: AgoraNetworkQuality, delay: UInt, lost: UInt) {
        //print( "Audio Quality of uid: \(uid), quality: \(quality.rawValue), delay: \(delay), lost: \(lost)")
        if lost > 50 {
            //delegate?.didLeave(with: uid)
            //ToastSuccess(title: "Poor signal", body: "You disconnected from the room because of poor signal.")
        }
    }
  
    /* Occurs when a method is executed by the SDK.
    *
    *  @param engine  - AgoraRtcEngineKit object.
    *  @param api - The method executed by the SDK.
    *  @param error - The error code ([AgoraErrorCode](https://docs.agora.io/en/Voice/API%20Reference/oc/Constants/AgoraErrorCode.html)) returned by the SDK when the method call fails. If the SDK returns 0, then the method call succeeds.
    *  @param result - The result of the method call.
    * - */
    func rtcEngine(_ engine: AgoraRtcEngineKit, didApiCallExecute api: String, error: Int) {
        //print( "Did api call execute: \(api), error: \(error)")
    }
    
    
    // Swift
    // Gets the the user IDs of the users with the highest peak volume, the corresponding volumes, as well as whether the local user is speaking.
    // @param speakers is an array containing the user IDs and volumes of the local and the remote users. The volume parameter ranges between 0 and 255.
    // @param totalVolume refers to the total volume after audio mixing, ranging between 0 and 255.
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers:
    [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        var res : [UInt:UInt] = [:]
        for s in speakers {
            res[s.uid] = s.volume
        }
        delegate?.volumeIndicator(from: res)
    }
    
}




func onDidOccurError( with code: Int ){
 
    //ToastSuccess(title: "Error code \(code)", body: "Please screen shot and show to developer")

    switch(code){
    case(17):
        //Toast(text: "Authenticating").show()
        break;
    case(18):
        break;
    case(101):
        break;
//        Toast(text: "Oh no! This app is not registered").show()
    case(102):
        break;
//      Toast(text: "Ugh, please pause and try again").show()
    case(116):
        break;
//      Toast(text: "Traffic is too high!").show()
    default:
        //Toast(text: "Bad connection!").show()
        break;
    }
}


func onDidOccurWarning( with code: Int ){

    //ToastSuccess(title: "Warn code \(code)", body: "Please screen shot and show to developer")

    switch(code){
    case (16):
        break
        // Toast(text:"Connecting...").show()
    case (104):
        //Toast(text: "Spotty wifi").show()
        break;
    case(1031):
        //Toast(text: "Your volume is all the way down").show()
        break
    default:
        break
        //Toast(text: "Warning: poor connection").show()
    }
}


