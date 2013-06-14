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
	import com.adobe.connect.synco.results.UserResult;
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import flash.external.ExternalInterface;
	
	import test.common.Test;
	
//	[SWF(width="10",height="10")]
	public class Test11_javascript_chat extends Test
	{
		private var chatMessages:Array = [];
		private var room:LiveRoom, podsObj:IMeetingObject, chatObj:IMeetingObject;
		
		public function Test11_javascript_chat()
		{
		}

		private function returnCommands(action:String,params:Array):void {
			switch(action) {
				case "chat":
					chatObj.serverCall("sendMessage",[0,params[0],-1,'Black',-1]);
					break;
			}
			trace(action,JSON.stringify(params));
		}

		override protected function init():void {
			ExternalInterface.addCallback("returnCommands", returnCommands);
			ExternalInterface.call("function(movieName){var isIE = navigator.appName.indexOf('Microsoft') != -1; parent.flashObj = isIE ? window[movieName] : document[movieName]; parent.returnCommands = function(action,params) {parent.flashObj.returnCommands(action,params);};}",ExternalInterface.objectID);
			ExternalInterface.call("(function(txt){if(!parent.chatbox)document.body.insertBefore(parent.chatbox=document.createElement('div'),document.body.firstChild);parent.chatbox.id='chatbox';parent.chatbox.style.position='absolute';})");
			ExternalInterface.call("(function(txt){if(!parent.inputbox)parent.chatbox.insertBefore(parent.inputbox=document.createElement('input'),parent.chatbox.firstChild); parent.inputbox.type='text'; parent.inputbox.addEventListener('keydown',function(event){ var keyCode = ('which' in event) ? event.which : event.keyCode; if(keyCode==13) { returnCommands('chat',[parent.inputbox.value]) ;parent.inputbox.value='';}; return; },false);})");
			ExternalInterface.call("(function(txt){if(!parent.msgbox)parent.chatbox.insertBefore(parent.msgbox=document.createElement('div'),parent.chatbox.firstChild);})");
			ExternalInterface.call('function(){setInterval(function(){chatbox.style.top = document.body.scrollTop+window.innerHeight-chatbox.offsetHeight;},10)}');
			
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
					trace(sequence.step,"check user");
					connect.session.fetchUser(sequence.next);
				},
				function(result:UserResult):void {
					trace(sequence.step,"User:",JSON.stringify(result.user));
					trace(sequence.step,"login");
					if(!result.user) {
						var seq:Sequence = new Sequence();
						seq.run(
							function():void {
								connect.session.logout(null,seq.next);
							},
							function():void {
								ExternalInterface.call("function(){parent.location='"+connect.session.url+"/system/login?next='+parent.location;}");
							}
						);
					}
					else {
						trace(sequence.step,"check user");
						connect.session.fetchUser(sequence.next);
					}
				},
				function(result:UserResult):void {
					trace(sequence.step,"enter room");
					room = connect.getRoom(meetingroom);
					room.enter(sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"Connected to",room.netConnection.uri);
					room.fetchMeetingObject(null,PodType.PODS,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					podsObj =result.meetingObject;
					trace(sequence.step,"Get Chat pod");
					var chatPodID:String;
					for(var id:String in podsObj.data) {
						if(podsObj.data[id].type=="FtChat") {
							chatPodID = id;
						}
					}
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
					receiveMessage.apply(null,result.data.history);
/*					"history": [
						{
							"fromPID": "922758255",
							"color": "Black",
							"text": "Hello, now it's Fri Oct 5 13:46:17 GMT-0700 2012",
							"fromName": "Vincent Le Quang",
							"type": 0,
							"when": 1349469922877,
							"toName": ""
						}
					]				*/
				}
			);
		}
		
		private function receiveMessage(...messages):void {
			chatMessages.push.apply(chatMessages,messages);
			chatMessages.sortOn("when");
			updateChatMessages();
		}
		
		private function updateChatMessages():void {
			var html:String = "";
			for each(var message:Object in chatMessages) {
				html += "<b>"+message.fromName+"</b>: ";
				html += "<font color='"+message.color+"'>"+message.text+"</font>";
				html +=  "<br>\n";
			}
			ExternalInterface.call("(function(txt){parent.msgbox.innerHTML = txt})",html);
		}
		
		private function clearHistory():void {
			trace(">> clearHistory");
			chatMessages = [];
			updateChatMessages();
		}
		
//		private function receiveMessage(msg:Object):void {
//			trace(">> receiveMessage:", JSON.stringify(msg,null,'\t'));
//		}
		
		override protected function log(...params):void {
			ExternalInterface.call("console.debug",">>"+params.join(" "));
//			ExternalInterface.call("(function(txt){parent.logger.appendChild(document.createTextNode(txt));})",params.join(" ")+"\n");
		}
	}
}