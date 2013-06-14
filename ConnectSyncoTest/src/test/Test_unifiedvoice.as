package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.interfaces.IMeetingStream;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.live.LiveStream;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.synco.results.MeetingStreamResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import flash.events.MouseEvent;
	import flash.events.SyncEvent;
	
	import test.common.Test;
	
	public class Test_unifiedvoice extends Test
	{
		private var audioObject:IMeetingObject;
		private var liveRoom:LiveRoom, audioStream:IMeetingStream;
		private var audioStreamId:String;
		public function Test_unifiedvoice()
		{
			description = "Listen to unified voice";
		}
		
		override protected function init():void {
			var connect:Connect;
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
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
					liveRoom = connect.getRoom(meetingroom);
					liveRoom.enter(sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"Connected to",liveRoom.netConnection.uri);
					liveRoom.fetchMeetingObject(null,PodType.UNIVOICE,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					audioObject = result.meetingObject;
					audioObject.sync = onAudioSync;
					trace("Click to stop audio");
					addEventListener(MouseEvent.CLICK,sequence.next);
				},
				function():void {
					liveRoom.leave();
				}
			);
		}
		
		private function startAudio(streamId:String):void {
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					liveRoom.fetchMeetingStream(streamId,LiveStream.PLAY,sequence.next);
				},
				function(result:MeetingStreamResult):void {
					trace(sequence.step,"Stream fetched");
					trace(sequence.step,"Start audio");
					audioStream = result.stream;
					audioStream.stream.receiveAudio(true);
					audioStream.stream.receiveVideo(false);
				}
			);
		}
		
		private function stopAudio(id:String):void {
			trace("Stop audio");
			liveRoom.closeNetStream(id);
		}
		
		private function onAudioSync(e:SyncEvent):void {
			
			var currentStreamId:String = audioObject.data.state=='disconnected' ? null : audioObject.data.streamId;
			if(audioStreamId != currentStreamId) {
				if(audioStreamId) {
					stopAudio(audioStreamId);
					audioStreamId = null;
				}
				if(currentStreamId) {
					audioStreamId = currentStreamId;
					startAudio(audioStreamId);
				}
			}
		}
	}
}