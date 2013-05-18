package com.adobe.connect.synco.live
{
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.interfaces.IMeetingStream;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.synco.results.MeetingStreamResult;
	import com.synco.script.Sequence;
	
	import flash.events.NetStatusEvent;
	import flash.net.NetStream;
	
	public class LiveStream implements IMeetingStream
	{
		static public const PUBLISH:String = "publish";
		static public const PLAY:String = "play";
		
		private var netStream:NetStream;
		private var _id:String;
		private var _room:LiveRoom;
		private var _mode:String;
		
		public function LiveStream()
		{
		}
		
		public function get id():String {
			return _id;
		}
		
		static public function create(id:String,mode:String,room:LiveRoom,callback:Function):LiveStream {
			var liveStream:LiveStream = new LiveStream();
			liveStream._id = id;
			liveStream._room = room;
			liveStream._mode = mode;
			liveStream.connect(callback);
			return liveStream;
		}
		
		private function connect(callback:Function):void {
			var sequence:Sequence = new Sequence();
			var self:LiveStream = this;
			sequence.run(
				function():void {
					_room.fetchMeetingObject(null,PodType.STREAMLIST,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					var streamListObject:IMeetingObject = result.meetingObject;
					var name:String = streamListObject.data[_id].streamName;
					netStream = new NetStream(_room.netConnection);
					netStream.client = {};
					netStream.addEventListener(NetStatusEvent.NET_STATUS,sequence.next);
					if(_mode==PLAY)
						netStream.play(name);
					else
						netStream.publish(name);
				},
				function(e:NetStatusEvent):void {
					if(e.info.code=="NetStream.Play.Start" || e.info.code=="NetStream.Publish.Start") {
						e.currentTarget.removeEventListener(e.type,arguments.callee);
						callback(new MeetingStreamResult(self));
					}
				}
			);
		}
				
		public function get stream():NetStream {
			return netStream;
		}
		
		public function get mode():String {
			return _mode;
		}
		
		public function close():void {
			netStream.close();
			netStream = null;
		}
	}
}