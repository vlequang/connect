package com.adobe.connect.widget.chat
{
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.widget.Connector;
	import com.adobe.connect.widget.core.Module;
	import com.synco.result.ArrayResult;
	import com.synco.result.DataResult;
	import com.synco.script.Sequence;

	public class ChatModule extends Module
	{
		private var chatObj:IMeetingObject;
		private var history:Array;
		private var _typing:Boolean;
		private var receivers:Vector.<IChatReceiver> = new Vector.<IChatReceiver>();
		
		public function ChatModule(connector:Connector)
		{
			super(connector);
		}
		
		override protected function connect():void {
			
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					connector.liveRoom.fetchActivePods("FtChat",sequence.next);
				},
				function(result:ArrayResult):void {
					var chatPodID:String = result.array[0];
					connector.liveRoom.fetchMeetingObject(chatPodID,PodType.CHATMESSAGES,null,sequence.next);
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