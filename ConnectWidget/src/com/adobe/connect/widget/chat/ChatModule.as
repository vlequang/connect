package com.adobe.connect.widget.chat
{
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.synco.result.ArrayResult;
	import com.synco.result.DataResult;
	import com.synco.script.Sequence;

	public class ChatModule
	{
		
		private var chatObj:IMeetingObject;
		private var history:Array;
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
	}
}