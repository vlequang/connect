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
	public class Test25_polls extends Test
	{
		private var pollObj:IMeetingObject, attendeeObj:IMeetingObject;
		
		public function Test25_polls()
		{
			var room:LiveRoom;
			var connect:Connect;
			var sequence:Sequence = new Sequence();;
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
					trace(sequence.step,"Get Attendee List");
					room.fetchMeetingObject(null,PodType.ATTENDEES,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					attendeeObj = result.meetingObject;
					trace(sequence.step,JSON.stringify(attendeeObj.data,null,"\t"));
					trace(sequence.step,"Get Poll pod");
					room.fetchActivePods("FtQuestion",sequence.next);
				},
				function(result:ArrayResult):void {
					var pollPodID:String = result.array[0];
					room.fetchMeetingObject(pollPodID,PodType.POLLQUESTIONS,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					pollObj = result.meetingObject;
					trace(JSON.stringify(pollObj.data,null,'\t'));
					pollObj.sync = onVote;
				}
			);
		}
		
		private function onVote(event:SyncEvent):void {
			var array:Array = [];
			var changed:Object = {};
			if(event) {
				for each(var change:Object in event.changeList) {
					changed[change.name] = true;
				}
			}
			for(var id:String in pollObj.data) {
				if(!isNaN(parseFloat(id))) {
					if(attendeeObj.data[id]) {
						var vote:int = parseInt(pollObj.data[id]);
						array.push(pollObj.data.info.answers[vote] + " - " + attendeeObj.data[id].fullName + (changed[id]?" *":""));
					}
				}
			}
			trace(JSON.stringify(array,null,'\t'));
		}
	}
}