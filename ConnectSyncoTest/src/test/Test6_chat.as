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
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import test.common.Test;
	
	public class Test6_chat extends Test
	{
		public function Test6_chat()
		{
			var room:LiveRoom;
			var podsObj:IMeetingObject;
			var chatObj:IMeetingObject;
			var connect:Connect;
			var sequence:Sequence = new Sequence();
			var layoutObject:IMeetingObject;
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
					trace(sequence.step,"Get Chat pod");
					room.fetchActivePods("FtChat",sequence.next);
				},
				function(result:ArrayResult):void {
					var chatPodID:String = result.array[0];
					room.fetchMeetingObject(chatPodID,PodType.CHATMESSAGES,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					chatObj = result.meetingObject;
					trace(sequence.step,"Register message events");
					chatObj.addCallback("message",receiveMessage);
					chatObj.addCallback("clearHistory",clearHistory);
					trace(sequence.step,"Get chat history");
					chatObj.serverCall("getHistory",[],sequence.next);
				},
				function(result:DataResult):void {
					trace(sequence.step,JSON.stringify(result.data,null,'\t'));
					trace(sequence.step,"Clear chat");
					chatObj.serverCall("clearHistory",[],sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"Get chat history");
					chatObj.serverCall("getHistory",[],sequence.next);
				},
				function(result:DataResult):void {
					trace(sequence.step,JSON.stringify(result.data,null,'\t'));
					trace(sequence.step,"Type message");
					chatObj.serverCall("setTypingStatus",[true],sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"Send a message");
					chatObj.serverCall("sendMessage",[0,"Hello, now it's "+new Date(),-1,'Black',-1],sequence.next);
				},
				function(result:Result):void {
					trace("Done");
					validate();
				}
			);
		}
		
		private function clearHistory():void {
			trace(">> clearHistory");
		}
		
		private function receiveMessage(msg:Object):void {
			trace(">> receiveMessage:", JSON.stringify(msg,null,'\t'));
		}
	}
}