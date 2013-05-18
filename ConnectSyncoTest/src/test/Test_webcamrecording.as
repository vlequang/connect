package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.interfaces.IMeetingStream;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.live.LiveStream;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.ConnectionResult;
	import com.adobe.connect.synco.results.DataResultResponder;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.synco.results.MeetingStreamResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.synco.result.ArrayResult;
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.SyncEvent;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.Video;
	
	import test.common.Test;

	public class Test_webcamrecording extends Test
	{
		private var recordingObject:IMeetingObject;
		
		public function Test_webcamrecording()
		{
			var videoPodID:String;
			var room:LiveRoom;
			var connect:Connect;
			var camera:Camera;
			var microphone:Microphone = Microphone.getEnhancedMicrophone();
			var sequence:Sequence = new Sequence();
			
			camera = Camera.getCamera(""+(Camera.names.length-1));
			camera.setMode(320,240,10);
			
			var video:Video = new Video();
			
			sequence.run(
				function():void {
					video.attachCamera(camera);
					camera.addEventListener(Event.VIDEO_FRAME,sequence.next);
				},
				function(e:Event):void {
					e.currentTarget.removeEventListener(e.type,sequence.currentCalls[0]);
					trace(sequence.step,"fetch connect");
					Connect.fetchConnect(domain,null,sequence.next);
				},
				function(result:ConnectResult):void {
					trace(sequence.step,"Connect Version:",result.version);
					connect = result.connect;
					trace(sequence.step,"check session");
					connect.session.fetchSession(sequence.next);
				},
				function(result:SessionResult):void {
					trace(sequence.step,"Session:",result.sessionID);
					trace(sequence.step,"Login");
					connect.session.login(username,password,null,sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"Enter room");
					room = connect.getRoom(meetingroom);
					room.enter(sequence.next);
				},
				function(result:ConnectionResult):void {
					trace(sequence.step,"Connected to",room.netConnection.uri);
					room.fetchMeetingObject(null,PodType.RECORDING,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					recordingObject = result.meetingObject;
					recordingObject.sync = recordSync;
					trace(sequence.step,"Start recording");
					if(recordingObject.data.isRecording)
					{
						if(recordingObject.data.isPaused) {
							room.serverCall("FtRecorder", "pauseRecording", [false], sequence.next);
						}
					}
					else {
						room.serverCall("FtRecorder","setRecord",[true,room.ticket,"Test "+new Date(),"Recording summary on"+new Date()],sequence.next);
					}
				},
				function():void {
					room.fetchActivePods("FtStage",sequence.next);
				},
				function(result:ArrayResult):void {
					videoPodID = result.array[0];
					room.netConnection.call("clientToServerCall", new DataResultResponder(sequence.next), videoPodID, "createNewStream", [room.userID]);
				},
				function(result:DataResult):void {
					room.fetchMeetingObject(videoPodID,PodType.VIDEO,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					var videoObject:IMeetingObject = result.meetingObject;
					room.fetchMeetingStream(videoObject.data[room.userID].streamId,LiveStream.PUBLISH,sequence.next);
				},
				function(result:MeetingStreamResult):void {
					var videoStream:IMeetingStream= result.stream;
					if(videoStream.stream) {
						videoStream.stream.receiveAudio(false);
						videoStream.stream.receiveVideo(false);
					}
					videoStream.stream.attachCamera(camera);
					
					room.netConnection.call("streamMgrCall", new DataResultResponder(sequence.next), "createNewStream", ["cameraVoip", "audio"]);
				},
				function(result:DataResult):void {
					var streamID:String = result.text;
					room.fetchMeetingStream(streamID,LiveStream.PUBLISH,sequence.next);
				},
				function(result:MeetingStreamResult):void {
					var audioStream:IMeetingStream= result.stream;
					if(audioStream.stream) {
						audioStream.stream.receiveAudio(false);
						audioStream.stream.receiveVideo(false);
					}
					audioStream.stream.attachAudio(microphone);
					
					addChild(video);

					trace(sequence.step,"Waiting for click for [Stop recording]");
					stage.addEventListener(MouseEvent.CLICK,sequence.next);
				},
				function(e:MouseEvent):void {
					e.currentTarget.removeEventListener(e.type,sequence.currentCalls[0]);
//					room.serverCall("FtRecorder", "pauseRecording", [true], sequence.next);
					room.serverCall("FtRecorder", "setRecord", [false], sequence.next);			
				},
				function():void {
					trace(sequence.step,"Leave Room");
					room.leave();
					trace(sequence.step,"Logout");
					connect.session.logout(null,sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"done");
					validate(result.success);
				}
			);
		}
		
		private function recordSync(event:SyncEvent):void
		{
			trace("recordingStatus:",JSON.stringify(recordingObject.data,null,'\t'));
		}
	}
}