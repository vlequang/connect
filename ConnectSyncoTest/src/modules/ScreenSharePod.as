package modules
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.interfaces.IMeetingStream;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.live.LiveStream;
	import com.adobe.connect.synco.pods.Pod;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.ConnectionResult;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.synco.results.MeetingStreamResult;
	import com.synco.result.ArrayResult;
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.media.Video;
	
	[SWF(backgroundColor="0x000000" , width="320" , height="240")]
	public class ScreenSharePod extends Pod
	{
		private static const VIDEO_WIDTH:int = 320,VIDEO_HEIGHT:int = 240;
		private var room:LiveRoom;
		private var videoStream:IMeetingStream;
		private var videoObject:IMeetingObject;
		private var videoContainer:Sprite = new Sprite();
		public function ScreenSharePod()
		{
			//	check parameters
			if(! (parameters.meetingroom) ) {
				throw new ArgumentError("Missing parameters 'meetingroom'");
				return;
			}
			
			init();
		}
		
		private function init():void {
			
			
			addChild(videoContainer);
			var connect:Connect;
			var sequence:Sequence = new Sequence();
			var idsToTry:Array;
			var screenShareID:String;
			var streamID:String;
			var meetingStream:IMeetingStream;
			sequence.run(
				function():void {
					Connect.fetchConnect(serverURL,parameters.session,sequence.next);
				},
				function(result:ConnectResult):void {
					connect = result.connect;
					room = connect.getRoom(parameters.meetingroom);
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
					sequence.jump(-1);
					sequence.next();
				},
				function(result:MeetingObjectResult):void {
					room.fetchMeetingStream(streamID,LiveStream.PLAY,sequence.next);
				},
				function(result:MeetingStreamResult):void {
					meetingStream = result.stream;
					var video:Video = videoContainer.getChildByName("video"+meetingStream.id) as Video;
					if(!video) {
						video = new Video(VIDEO_WIDTH,VIDEO_HEIGHT);
						//video.smoothing = true;
						video.name = "video"+meetingStream.id;
						videoContainer.addChild(video);
						resetLayout();
					}
					video.attachNetStream(meetingStream.stream);
					videoContainer.addChild(video);
				}
			);
		}
		
		private function stopVideo(id:String):void {
			var video:Video = videoContainer.getChildByName("video"+id) as Video;
			if(video) {
				videoContainer.removeChild(video);
				video.attachNetStream(null);
				room.closeNetStream(id);
				resetLayout();
			}
		}
		
		private function startVideo(id:String):void {
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					room.fetchMeetingStream(videoObject.data[id].streamId,LiveStream.PLAY,sequence.next);
				},
				function(result:MeetingStreamResult):void {
					videoStream = result.stream;
					trace(sequence.step,"Stream fetched");
					trace(sequence.step,"Start video");
					var video:Video = videoContainer.getChildByName("video"+id) as Video;
					if(!video) {
						video = new Video(VIDEO_WIDTH,VIDEO_HEIGHT);
						video.name = "video"+id;
						videoContainer.addChild(video);
						resetLayout();
					}
					video.attachNetStream(videoStream.stream);
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
				var cols:int = videoCount/rows;
				var totalWidth:int = cols*VIDEO_WIDTH;
				var totalHeight:int = rows*VIDEO_HEIGHT;
				var scale:Number = Math.min(stage.stageWidth/totalWidth,stage.stageHeight/totalHeight);
				if(scale>bestScale) {
					bestCols = cols;
					bestScale = scale;
				}
			}
			bestRows = videoCount/bestCols;
			for(var i:int=0;i<videoCount;i++) {
				var child:DisplayObject = videoContainer.getChildAt(i);
				child.x = (i%bestCols)*VIDEO_WIDTH;
				child.y = int(i/bestCols)*VIDEO_HEIGHT;
			}
			videoContainer.scaleX = videoContainer.scaleY = bestScale;
			videoContainer.x = (stage.stageWidth-bestCols*VIDEO_WIDTH*bestScale)/2
			videoContainer.y = (stage.stageHeight-bestRows*VIDEO_HEIGHT*bestScale)/2
		}
		
		private function onSync(changeList:Array):void {
			var changes:Object = null;
			if(changeList) {
				changes = {};
				for each(var change:Object in changeList) {
					if(change.code=="change") {
						changes[change.name] = change;
					}
					else if(change.code=="delete") {
						stopVideo(change.name);
					}
				}
			}
			
			for(var i:String in videoObject.data) {
				if(!changes || changes[i]) {
					startVideo(i);
				}
			}
		}
	}
}