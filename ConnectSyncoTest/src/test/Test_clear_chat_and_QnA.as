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

	public class Test_clear_chat_and_QnA extends Test
	{
		private var chat_sequence:Sequence;
		private var qna_sequence:Sequence;
		private var connect:Connect;
		
		public function Test_clear_chat_and_QnA()
		{
			description = "Clear the chat pod and Q&A pod";
		}
		
		override protected function init():void {
			initialize_sequences();
			
			var sequence:Sequence = new Sequence();
			sequence.run(
				chat_sequence,
				qna_sequence
			);
		}
		
		private function initialize_sequences():void {
			//	LOGIN SEQUENCE
			var login_sequence:Sequence = new Sequence();
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
					connect.session.fetchUser(login_sequence.next);
				},
				function(result:UserResult):void {
					if(!result.user) {
						trace(login_sequence.stepProgress,"login");
						connect.session.login(username,password,null,login_sequence.next);
					}
					else {
						login_sequence.next(result);
					}
				}
			);
			
			//	ENTER ROOM SEQUENCE
			var room:LiveRoom;
			var enter_room_sequence:Sequence = new Sequence();
			enter_room_sequence.assign(
				login_sequence,
				function(result:Result):void {
					if(!room) {
						trace(enter_room_sequence.stepProgress,"enter room");
						room = connect.getRoom(meetingroom);
					}
					if(!room.connected) {
						room.enter(enter_room_sequence.next);
					}
					else {
						enter_room_sequence.next(new Result(true));
					}
				}
			);
			
			//	GET POD SEQUENCE
			var podsObj:IMeetingObject;
			var pod_sequence:Sequence = new Sequence();
			pod_sequence.assign(
				enter_room_sequence,
				function(result:Result):void {
					trace(pod_sequence.stepProgress,"Get pod list");
					room.fetchMeetingObject(null,PodType.PODS,null,pod_sequence.next);
				},
				function(result:MeetingObjectResult):void {
					podsObj = result.meetingObject;
					pod_sequence.next();
				}
			);
			
			//	CLEAR CHAT POD SEQUENCE
			chat_sequence = new Sequence();
			chat_sequence.assign(
				pod_sequence,
				function(result:Result):void {
					trace(chat_sequence.stepProgress,"Get Chat pod");
					for(var id:String in podsObj.data) {
						if(podsObj.data[id].type=="FtChat") {
							room.fetchMeetingObject(id,PodType.CHATMESSAGES,null,chat_sequence.next);
							break;
						}
					}
				},
				function(result:MeetingObjectResult):void {
					var chatObj:IMeetingObject = result.meetingObject;					
					chatObj.serverCall("clearHistory",[],chat_sequence.next);
				},
				function(result:Result):void {
					trace(chat_sequence.stepProgress,"Clear chat history");
					chat_sequence.next();
				}
			);
			
			// CLEAR QNA POD SEQUENCE
			qna_sequence = new Sequence();
			qna_sequence.assign(
				pod_sequence,
				function(result:Result):void {
					trace(qna_sequence.stepProgress,"Get QNA pod");
					for(var id:String in podsObj.data) {
						if(podsObj.data[id].type=="QandA") {
							room.fetchMeetingObject(id,PodType.CHATMESSAGES,null,qna_sequence.next);
							break;
						}
					}
				},
				function(result:MeetingObjectResult):void {
					var qnaObj:IMeetingObject = result.meetingObject;
					qnaObj.serverCall("onDeleteAllQuestions",[],qna_sequence.next);
				},
				function(result:Result):void {
					trace(qna_sequence.stepProgress,"Cleared QnA history");
					qna_sequence.next();
				}
			);
		}
	}
}