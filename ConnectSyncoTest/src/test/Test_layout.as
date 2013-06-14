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
	
	import test.common.Test;
	
	public class Test_layout extends Test
	{
		public function Test_layout()
		{
			description = "View the layout of a meeting";
		}
		
		override protected function init():void {
			var connect:Connect;
			var room:LiveRoom;
			var saveStateObj:IMeetingObject, layoutObj:IMeetingObject, 
				activeLayout:Object;
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
					trace(sequence.step,"login");
					connect.session.login(username,password,null,sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"enter room");
					room = connect.getRoom(meetingroom);
					room.enter(sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"Fetch current layout");
					room.fetchMeetingObject(null,PodType.LAYOUT_SAVEDSTATE,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					saveStateObj = result.meetingObject;
					trace(sequence.step,JSON.stringify(result.meetingObject.data,null,'\t'));
					trace(sequence.step,"Fetch layout information");
					room.fetchMeetingObject(null,PodType.LAYOUT_LAYOUT,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					layoutObj = result.meetingObject;
					trace(sequence.step,"Show active layout");
					activeLayout = layoutObj.data[saveStateObj.data.roomLayoutID];
					trace(sequence.step,JSON.stringify(activeLayout,null,'\t'));
					room.fetchMeetingObject(null,PodType.PODS,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					trace(sequence.step,JSON.stringify(result.meetingObject.data,null,"\t"));
					trace(sequence.step,"done");
					validate();
				}
			);
		}
	}
}