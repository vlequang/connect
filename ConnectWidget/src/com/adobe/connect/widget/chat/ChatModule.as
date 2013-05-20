package com.adobe.connect.widget.chat
{
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.synco.result.ArrayResult;
	import com.synco.result.DataResult;
	import com.synco.script.Sequence;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class ChatModule extends EventDispatcher
	{
		private var connected:Boolean;
		private var chatObj:IMeetingObject;
		private var history:Array;
		private var _typing:Boolean;
		private var receivers:Vector.<IChatReceiver> = new Vector.<IChatReceiver>();
		
		public function ChatModule(liveRoom:LiveRoom)
		{
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					liveRoom.fetchActivePods("FtChat",sequence.next);
				},
				function(result:ArrayResult):void {
					var chatPodID:String = result.array[0];
					liveRoom.fetchMeetingObject(chatPodID,PodType.CHATMESSAGES,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					chatObj = result.meetingObject;
					chatObj.addCallback("message",receiveMessage);
					chatObj.serverCall("getHistory",[],sequence.next);
				},
				function(result:DataResult):void {
					history = result.data.history;
					receiveHistory(history);
					connected = true;
					dispatchEvent(new Event(Event.CONNECT));
				}
			);
			/*,
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
					}*/
		}
		
		public function addReceiver(receiver:IChatReceiver,updateHistory:Boolean):Boolean {
			if(receivers.indexOf(receiver)<0) {
				receivers.push(receiver);
				if(updateHistory) {
					for each(var message:Object in history) {
						receiver.receiveMessage(message);
					}
				}
				return true;
			}
			return false;
		}
		
		private function receiveMessage(message:Object):void {
			history.push(message);
			for each(var receiver:IChatReceiver in receivers) {
				receiver.receiveMessage(message);
			}
		}
		
		private function receiveHistory(history:Array):void {
			this.history = history;
			for each(var receiver:IChatReceiver in receivers) {
				for each(var message:Object in history) {
					receiver.receiveMessage(message);
				}
			}
		}
		
		private function waitForConnection(args:Array):Boolean {
			if(connected) {
				return false;
			}
			addEventListener(Event.CONNECT,
				function(e:Event):void {
					e.currentTarget.removeEventListener(e.type,arguments.callee);
					args.callee.apply(null,args);
				});
			return true;
		}
		
		public function sendMessage(message:String):void {
			if(waitForConnection(arguments))
				return;
			chatObj.serverCall("sendMessage",[0,message,-1,'Black',-1]);
		}
		
		public function set typing(value:Boolean):void {
			if(waitForConnection(arguments))
				return;
			if(_typing!=value) {
				_typing = value;
				chatObj.serverCall("setTypingStatus",[true]);
			}
		}
	}
}