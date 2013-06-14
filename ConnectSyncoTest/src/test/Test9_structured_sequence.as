package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.adobe.connect.synco.results.UserResult;
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import test.common.Test;

	public class Test9_structured_sequence extends Test
	{
		private var login_sequence:Sequence;
		private var pod_sequence:Sequence;
		private var chat_sequence:Sequence;
		
		public function Test9_structured_sequence()
		{
		}
		
		override protected function init():void {
			initialize_sequences();
			
			var sequence:Sequence = new Sequence();
			sequence.run(
				login_sequence,
				pod_sequence,
				chat_sequence,
				function():void {
					trace("Done");
				}
			);
		}
		
		private function initialize_sequences():void {
			//	ENTER ROOM SEQUENCE
			var room:LiveRoom;
			var connect:Connect;
			login_sequence = new Sequence();
			login_sequence.assign(
				function():void {
					trace(login_sequence.stepProgress,"fetch connect");
					Connect.fetchConnect(domain,null,login_sequence.next);
				},
				function(result:ConnectResult):void {
					trace(login_sequence.stepProgress,"Connect Version:",result.version);
					connect = result.connect;
					trace(login_sequence.stepProgress,"check session");
					connect.session.fetchSession(login_sequence.next);
				},
				function(result:SessionResult):void {
					trace(login_sequence.stepProgress,"Session:",result.sessionID);
					trace(login_sequence.stepProgress,"check user");
					connect.session.fetchUser(login_sequence.next);
				},
				function(result:UserResult):void {
					trace(login_sequence.stepProgress,"User:",JSON.stringify(result.user));
					if(result.user) {
						if(result.user.login==username) {
							trace(login_sequence.stepProgress,"Jump 3 steps");
							login_sequence.jump(3);
							login_sequence.next(result);
						}
						else {
							trace(login_sequence.stepProgress,"logout");
							connect.session.logout(null,login_sequence.next);
						}
					}
					else {
						login_sequence.next(new Result(true));
					}
				},
				function(result:Result):void {					
					trace(login_sequence.stepProgress,"login");
					connect.session.login(username,password,null,login_sequence.next);
				},
				function(result:Result):void {
					trace(login_sequence.stepProgress,"check user");
					connect.session.fetchUser(login_sequence.next);
				},
				function(result:UserResult):void {
					trace(login_sequence.stepProgress,"User:",JSON.stringify(result.user));
					trace(login_sequence.stepProgress,"enter room");
					room = connect.getRoom(meetingroom);
					room.enter(login_sequence.next);
				}
			);
			
			//	GET CHAT POD SEQUENCE
			var podsObj:IMeetingObject;
			var chatObj:IMeetingObject;
			pod_sequence = new Sequence();
			pod_sequence.assign(
				function():void {
					trace(pod_sequence.stepProgress,"Connected to",room.netConnection.uri);
					room.fetchMeetingObject(null,PodType.PODS,null,pod_sequence.next);
				},
				function(result:MeetingObjectResult):void {
					podsObj = result.meetingObject;
					trace(pod_sequence.stepProgress,"Get Chat pod");
					var chatPodID:String;
					for(var id:String in podsObj.data) {
						if(podsObj.data[id].type=="FtChat") {
							chatPodID = id;
						}
					}
					room.fetchMeetingObject(chatPodID,PodType.CHATMESSAGES,null,pod_sequence.next);
				},
				function(result:MeetingObjectResult):void {
					chatObj = result.meetingObject;
					trace(pod_sequence.stepProgress,"Register message events");
					chatObj.addCallback("message",receiveMessage);
					chatObj.addCallback("clearHistory",clearHistory);
					trace(pod_sequence.stepProgress,"Get chat history");
					chatObj.serverCall("getHistory",[],pod_sequence.next);
				}
			);
			
			//	CHAT SEQUENCE
			chat_sequence = new Sequence();
			chat_sequence.assign(
				function(result:DataResult):void {
					trace(chat_sequence.stepProgress,JSON.stringify(result.data,null,'\t'));
					trace(chat_sequence.stepProgress,"Clear chat");
					chatObj.serverCall("clearHistory",[],chat_sequence.next);
				},
				function(result:Result):void {
					trace(chat_sequence.stepProgress,"Get chat history");
					chatObj.serverCall("getHistory",[],chat_sequence.next);
				},
				function(result:DataResult):void {
					trace(chat_sequence.stepProgress,JSON.stringify(result.data,null,'\t'));
					trace(chat_sequence.stepProgress,"Type message");
					chatObj.serverCall("setTypingStatus",[true],chat_sequence.next);
				},
				function(result:Result):void {
					trace(chat_sequence.stepProgress,"Send a message");
					chatObj.serverCall("sendMessage",[0,"Hello, now it's "+new Date(),-1,'Black',-1],chat_sequence.next);
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