package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.live.LiveObject;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import test.common.Test;

	public class Test_pods extends Test
	{
		public function Test_pods()
		{
			description = "Lists the pods in a meeting";
		}
		
		override protected function init():void {
			var connect:Connect;
			var room:LiveRoom;
			var sequence:Sequence = new Sequence();
			var podsObj:IMeetingObject, layoutObj:IMeetingObject, saveStateObj:IMeetingObject;
			var activeLayout:Object;
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
					trace(sequence.step,"Fetch current layout");
					room.fetchMeetingObject(null,PodType.LAYOUT_SAVEDSTATE,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					saveStateObj = result.meetingObject;
					trace(sequence.step,JSON.stringify(result.meetingObject.data,null,'\t'));
					trace(sequence.step,"Fetch layout information");
					room.fetchMeetingObject(null,PodType.LAYOUT_LAYOUT,null,sequence.next);
					room.fetchMeetingObject(null,PodType.PODS,null,sequence.next);
				},
				function(layoutResult:MeetingObjectResult, podsResult:MeetingObjectResult):void {
					layoutObj = layoutResult.meetingObject;
					podsObj = podsResult.meetingObject;
					trace(sequence.step,"Show active layout");
					activeLayout = layoutObj.data[saveStateObj.data.roomLayoutID];
					trace(sequence.step,JSON.stringify(activeLayout,null,'\t'));
					trace(sequence.step,"Show active pods");
					var screenShareID:String;
					for(var id:String in activeLayout.modules) {
						if(activeLayout.modules[id].type=="FtContent")
							screenShareID = id;
						trace(sequence.step,JSON.stringify(podsObj.data[id],null,"\t"));
					}
					trace(sequence.step,"done");
					validate();
				}
			);
		}
	}
}