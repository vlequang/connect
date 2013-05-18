package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import test.common.Test;

	public class Test7_QandA extends Test
	{
		public function Test7_QandA()
		{
			var room:LiveRoom;
			var podsObj:IMeetingObject;
			var qnaObj:IMeetingObject;
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
					trace(sequence.step,"login");
					connect.session.login(username,password,null,sequence.next);
				},
				function(result:Result):void {
					trace("Login:",JSON.stringify(result));
					if(!result.success)
						return;
					trace(sequence.step,"enter room");
					room = connect.getRoom(meetingroom);
					room.enter(sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"Connected to",room.netConnection.uri);
					room.fetchMeetingObject(null,PodType.PODS,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					podsObj = result.meetingObject;
					trace(sequence.step,"Get Q&A pod");
					var qnaPodID:String;
					for(var id:String in podsObj.data) {
						if(podsObj.data[id].type=="QandA") {
							qnaPodID = id;
						}
					}
					room.fetchMeetingObject(qnaPodID,PodType.CHATMESSAGES,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					qnaObj = result.meetingObject;
					trace(sequence.step,"Register message events");
					trace(sequence.step,"Get Q&A history");
					qnaObj.serverCall("getHistory",[],sequence.next);
				},
				function(result:DataResult):void {
					trace(sequence.step,JSON.stringify(result.data,null,'\t'));
					trace(sequence.step,"Delete all questions");
					qnaObj.serverCall("onDeleteAllQuestions",[],sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"Get Q&A history");
					qnaObj.serverCall("getHistory",[],sequence.next);
				},
				function(result:DataResult):void {
					trace(sequence.step,JSON.stringify(result.data,null,'\t'));
					trace("Done");
					validate();
				}
			);
		}
	}
}