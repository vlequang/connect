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
		private var connectCore:Connect;
		public var liveRoom:LiveRoom;
		private var modules:Object = {};
		public var connected:Boolean;
		
		public function connect(url:String,room:String,guestName:String,password:String=null):void
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
					if(!password) {
						liveRoom.enterAsGuest(guestName,sequence.next);
					}
					else {
						liveRoom.enterLogin(guestName,password,sequence.next);
					}
				},
				function(result:ConnectionResult):void {
					connected = true;
					dispatchEvent(new Event(Event.CONNECT));
				}
			);
		}
		
		public function get chat():ChatModule {
			return modules.chat || (modules.chat = new ChatModule(this));
		}
	}
}