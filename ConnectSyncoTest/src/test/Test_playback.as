package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.live.LiveStream;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.ConnectionResult;
	import com.adobe.connect.synco.results.MeetingStreamResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.adobe.connect.synco.results.UserResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.media.Video;
	import flash.net.NetStream;
	
	import test.common.ProxyClient;
	import test.common.Test;

	public class Test_playback extends Test
	{
		private var room:LiveRoom;
		private var videoContainer:Sprite = new Sprite();
		public function Test_playback()
		{
			description = "Replay a meeting";
		}
		
		override protected function init():void {
			addChild(videoContainer);
			
			meetingroom = "p16wz2x0lnw";
//https://my.adobeconnect.com/fieldenablement/			
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
					trace(sequence.step,"Login");
					connect.session.login(username,password,null,sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"Enter room");
					room = connect.getRoom(meetingroom);
					room.enter(sequence.next);
				},
				function(result:ConnectionResult):void {
					room.netConnection.proxyType = "best";
					trace(sequence.step,"Connected to",room.netConnection.uri);
					var ns:NetStream = new NetStream(room.netConnection);
					room.netConnection.addEventListener(NetStatusEvent.NET_STATUS,
						function(e:NetStatusEvent):void{
							trace(e.info.code);
						});
					ns.addEventListener(NetStatusEvent.NET_STATUS,
						function(e:NetStatusEvent):void{
							trace(e.info.code);
						});
					ns.bufferTime = .1;
					ns.client = {playEvent:onPlayEvent};
//					ns.play("/transcriptstream", 0, -1, 3);
					
					var indexStream:NetStream = new NetStream(room.netConnection);
					indexStream.bufferTime = .1;
					indexStream.client = new ProxyClient({onMetaData:onMetaData, playEvent:onPlayEvent,handleCursorDataMessage:handleCursorDataMessage});
					indexStream.play("/indexstream", 0, -1, 3);
					
//					/indexstream
					
				},
				function(result:MeetingStreamResult):void {
					trace(result.success);
				},
				function(result:Result):void {
					trace(sequence.step,"Leave Room");
					room.leave();
					trace(sequence.step,"Logout");
					connect.session.logout(null,sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"done");
					validate();
				}
			);
		}
		
		private function handleCursorDataMessage(x:Number, y:Number, typeId:int, button:Boolean):void {
			
		}
		
		private function onPlayEvent(...params):void {
			var obj:Object = params[0];
			if(obj=="__start__") {
				
			}
			else if(obj=="__stop__") {
				
			}
			else {
				handlePlayEvent(obj.name,params);
			}
		}
		
		private function handlePlayEvent(name:String,params:Array):void {
			switch(name) {
				case "StreamManagerId_Mainstream":
					handleStreamEvent(params[0].id,params[0].time,params[1],params[2][0]);
					break;
				default:
//					trace(JSON.stringify(params));
			}
		}
		
		private function handleStreamEvent(id:String,time:int,eventType:String,streamInfo:Object):void {
			if(eventType=="streamAdded") {
				if(streamInfo.streamType=="screenshare" || streamInfo.streamType=="cameraVoip") {
					var ns:NetStream = new NetStream(room.netConnection);
					ns.play(streamInfo.streamName);
	//				ns.addEventListener(NetStatusEvent.NET_STATUS,trace);
					ns.client = new ProxyClient({onMetaData:onMetaData, pacingTick:pacingTick});
					ns.seek(40*60);
					var video:Video = new Video();
					video.addEventListener(Event.ENTER_FRAME,
						function(e:Event):void {
							var video:Video = e.currentTarget as Video;
							if(video.videoWidth && video.videoHeight) {
								video.width = video.videoWidth;
								video.height = video.videoHeight;
								arrangeLayout();
								e.currentTarget.removeEventListener(e.type,arguments.callee);
							}
						});
					video.attachNetStream(ns);
					videoContainer.addChild(video);
					arrangeLayout();
				}
			}
		}
		
		private function arrangeLayout():void {
			var y:int = 0;
			for(var i:int=0;i<videoContainer.numChildren;i++) {
				var video:Video = videoContainer.getChildAt(i) as Video;
				video.y = y;
				y += video.height;
			}
			videoContainer.width = stage.stageWidth;
			videoContainer.height = stage.stageHeight;
			if(videoContainer.scaleX>videoContainer.scaleY)
				videoContainer.scaleX = videoContainer.scaleY;
			else
				videoContainer.scaleY = videoContainer.scaleX;
			addChild(videoContainer);
		}
		
		private function pacingTick(num:int):void {
			
		}
		
		private function onMetaData(...obj):void {
			trace(JSON.stringify(obj,null,'\t'));
		}
	}	
}