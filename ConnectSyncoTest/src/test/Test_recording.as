package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.ConnectionResult;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.adobe.connect.synco.results.UserResult;
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import flash.events.MouseEvent;
	import flash.events.SyncEvent;
	
	import test.common.Test;

	public class Test_recording extends Test
	{
		private var recordingObject:IMeetingObject;
		
		public function Test_recording()
		{
			description = "Start/Pause/Stop recording a meeting.";
		}
		
		override protected function init():void {
			var room:LiveRoom;
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
					room.serverCall("FtRecorder","setRecord",[true,room.ticket,"Test "+new Date(),"Recording summary on"+new Date()],sequence.next);
				},
				function(result:DataResult):void {
					trace(sequence.step,"Waiting for click for [Pause]");
					stage.addEventListener(MouseEvent.CLICK,sequence.next);
				},
				function(e:MouseEvent):void {
					e.currentTarget.removeEventListener(e.type,sequence.currentCalls[0]);
					room.serverCall("FtRecorder", "pauseRecording", [true], sequence.next);
				},
				function(result:DataResult):void {
					trace(sequence.step,"Waiting for click for [UnPause]");
					stage.addEventListener(MouseEvent.CLICK,sequence.next);
				},
				function(e:MouseEvent):void {
					e.currentTarget.removeEventListener(e.type,sequence.currentCalls[0]);
					room.serverCall("FtRecorder", "pauseRecording", [false], sequence.next);
				},
				function(result:DataResult):void {
					trace(sequence.step,"Waiting for click for [Stop recording]");
					stage.addEventListener(MouseEvent.CLICK,sequence.next);
				},
				function(e:MouseEvent):void {
					e.currentTarget.removeEventListener(e.type,sequence.currentCalls[0]);
					room.serverCall("FtRecorder", "setRecord", [false], sequence.next);			
				},
				function(result:DataResult):void {
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