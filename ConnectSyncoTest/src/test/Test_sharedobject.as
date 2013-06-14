package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import flash.events.SyncEvent;
	import flash.net.SharedObject;
	
	import test.common.Test;

	public class Test_sharedobject extends Test
	{
		public function Test_sharedobject()
		{
			description = "Use a custom shared object in a room";
		}
		
		override protected function init():void {
			var connect:Connect;
			var room:LiveRoom;
			var sequence:Sequence = new Sequence();
			var so:SharedObject;
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
					trace(sequence.step,"login");
					connect.session.login(username,password,null,sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"enter room");
					room = connect.getRoom(meetingroom);
					room.enter(sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"Connected to",room.netConnection.uri);
					so = SharedObject.getRemote("connect_so",room.netConnection.uri);
					so.addEventListener(SyncEvent.SYNC,sequence.next);
					so.connect(room.netConnection);
				},
				function(event:SyncEvent):void {
					trace(JSON.stringify(event.changeList));
				}
			);
		}
	}
}