package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.synco.result.ArrayResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import flash.events.SyncEvent;
	
	import test.common.Test;
	
	[SWF(width="800", height="600"]
	public class Test26_user extends Test
	{
		private var pollObj:IMeetingObject, attendeeObj:IMeetingObject;
		
		public function Test26_user()
		{
		}
		
		override protected function init():void {
			var room:LiveRoom;
			var connect:Connect;
			var sequence:Sequence = new Sequence();
			var attendees:IMeetingObject, userInfo:Object;
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
//					room.enterAsGuest("Test",sequence.next);
					room.enter(sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"Connected to",room.netConnection.uri);
					room.fetchMeetingObject(null,PodType.ATTENDEES,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					attendees = result.meetingObject;
					userInfo = attendees.data[room.userID];
//					userInfo.phoneNumber = "8881001000";
//					userInfo.fullName = "ABABAB";
					userInfo.isMobileUser = true;
					room.serverCall("userMgrCall","editUserDetailsAt",[parseFloat(room.userID), {name:"AAA",fullName:"AAA"}], trace);
				}
			);
		}
	}
}