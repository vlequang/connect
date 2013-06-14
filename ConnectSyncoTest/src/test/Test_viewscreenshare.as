package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.interfaces.IMeetingStream;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.live.LiveStream;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.ConnectionResult;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.synco.results.MeetingStreamResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.synco.result.ArrayResult;
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.media.Video;
	
	import test.common.Test;
	
//	[SWF(backgroundColor="0x000000" , width="1024" , height="768")]
	public class Test_viewscreenshare extends Test
	{
		private var videoContainer:Sprite = new Sprite();
		private static const VIDEO_WIDTH:int = 320,VIDEO_HEIGHT:int = 240;
		
		public function Test_viewscreenshare()
		{
			description = "View a screen shared from another computer";
		}
		
		override protected function init():void {
			var connect:Connect;
			var room:LiveRoom;
			var sequence:Sequence = new Sequence();
			var meetingStream:IMeetingStream;
			var activeLayout:Object;
			var screenShareID:String;
			var streamID:String;
			var idsToTry:Array;
			var screenShareInfo:IMeetingObject;
			addChild(videoContainer);
			sequence.run(
				function():void {
					trace(sequence.step,"fetch connect");
					Connect.fetchConnect(domain,null,sequence.next);
				},
				function(result:ConnectResult):void {
					trace(sequence.step,"Connect Version:",result.version);
					connect = result.connect;
					connect.session.login(username,password,null,sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"enter room");
					room = connect.getRoom(meetingroom);
					room.enter(sequence.next);
				},
				function(result:ConnectionResult):void {
					trace(sequence.step,"Connected to",room.netConnection.uri);
					trace(sequence.step,"Fetch active pods");
					room.fetchActivePods("FtContent",sequence.next);
				},
				function(result:ArrayResult):void {
					idsToTry = result.array;
					idsToTry.reverse();
					sequence.next();
				},
				function():void {
					if(idsToTry.length) {
						screenShareID = idsToTry.pop();
						room.fetchContent(screenShareID,sequence.next);
					}
				},
				function(result:DataResult):void {
					trace(JSON.stringify(result.data,null,'\t'));
					if(result.success && result.data.shareType=='screen') {
						streamID = result.data.screenDescriptor.streamID;
						room.fetchMeetingObject(result.data.ctID,PodType.SCREENSHARE,null,sequence.next);
					}
					else {
						sequence.jump(-1);
						sequence.next();
					}
				},
				function(result:MeetingObjectResult):void {
					screenShareInfo = result.meetingObject;
					room.fetchMeetingStream(streamID,LiveStream.PLAY,sequence.next);
				},
				function(result:MeetingStreamResult):void {
					meetingStream = result.stream;
					var video:Video = videoContainer.getChildByName("video"+meetingStream.id) as Video;
					if(!video) {
						var w:int = screenShareInfo.data.w;
						var h:int = screenShareInfo.data.h;
						var scale:Number = Math.min(VIDEO_WIDTH/w,VIDEO_HEIGHT/h);
						video = new Video(w*scale,h*scale);
						video.smoothing = true;
						video.name = "video"+meetingStream.id;
						videoContainer.addChild(video);
						resetLayout();
					}
					video.attachNetStream(meetingStream.stream);
					videoContainer.addChild(video);
				}
			);
		}
		
		private function resetLayout():void {
			var videoCount:int= videoContainer.numChildren;
			//	find best configuration
			var bestCols:int;
			var bestRows:int;
			var bestScale:Number = 0;
			for(var rows:int=1;rows<=videoCount;rows++) {
				var cols:int = Math.ceil(videoCount/rows);
				var totalWidth:int = cols*VIDEO_WIDTH;
				var totalHeight:int = rows*VIDEO_HEIGHT;
				var scale:Number = Math.min(stage.stageWidth/totalWidth,stage.stageHeight/totalHeight);
				if(scale>bestScale) {
					bestCols = cols;
					bestScale = scale;
				}
			}
			bestRows = Math.ceil(videoCount/bestCols);
			for(var i:int=0;i<videoCount;i++) {
				var child:DisplayObject = videoContainer.getChildAt(i);
				child.x = (i%bestCols)*VIDEO_WIDTH + (VIDEO_WIDTH-child.width)/2;
				child.y = int(i/bestCols)*VIDEO_HEIGHT + (VIDEO_HEIGHT-child.height)/2;
			}
			videoContainer.scaleX = videoContainer.scaleY = bestScale;
			videoContainer.x = (stage.stageWidth-bestCols*VIDEO_WIDTH*bestScale)/2
			videoContainer.y = (stage.stageHeight-bestRows*VIDEO_HEIGHT*bestScale)/2
		}
	}
}