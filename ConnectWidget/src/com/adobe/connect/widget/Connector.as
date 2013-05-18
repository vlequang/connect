package com.adobe.connect.widget
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.ConnectionResult;
	import com.adobe.connect.widget.chat.ChatModule;
	import com.synco.script.Sequence;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;

	[Event(name="connect", type="flash.events.Event")]
	public class Connector extends EventDispatcher
	{
		private var meetingURL:String;
		private var liveRoom:LiveRoom, connectCore:Connect;
		
		private var _chat:ChatModule;
		
		public function connect(url:String,room:String,guestName:String):void
		{
			meetingURL = url;
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					trace(sequence.step,"fetch connect");
					Connect.fetchConnect(meetingURL,null,sequence.next);
				},
				function(result:ConnectResult):void {
					trace(sequence.step,"Connect Version:",result.version);
					connectCore = result.connect;
					liveRoom = connectCore.getRoom(room);
					liveRoom.enterAsGuest(guestName,sequence.next);
				},
				function(result:ConnectionResult):void {
					dispatchEvent(new Event(Event.CONNECT));
				}
			);
		}
		
		private function ensureConnection():void {
			if(!liveRoom) {
				throw new Error("Not connected");
			}
		}
		
		public function get chat():ChatModule {
			ensureConnection();
			return _chat || (_chat = new ChatModule(liveRoom));
		}
	}
}