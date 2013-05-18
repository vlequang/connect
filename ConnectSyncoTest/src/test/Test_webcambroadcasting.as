package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.interfaces.IMeetingStream;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.live.LiveStream;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.synco.results.MeetingStreamResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.adobe.connect.synco.results.UserResult;
	import com.synco.result.ArrayResult;
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.SyncEvent;
	import flash.geom.Point;
	import flash.media.Camera;
	import flash.media.Video;
	
	import test.common.Test;
	
	public class Test_webcambroadcasting extends Test
	{
		private static const VIDEO_WIDTH:int = 320,VIDEO_HEIGHT:int = 240;
		private var room:LiveRoom;
		private var videoStream:IMeetingStream;
		private var videoObject:IMeetingObject;
		private var netStreams:Object ={};
		private var videoContainer:Sprite = new Sprite();
		private var camera:Camera;
		public function Test_webcambroadcasting()
		{
			addChild(videoContainer);
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
					connect.session.login(username,password,null,sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"check user");
					connect.session.fetchUser(sequence.next);
				},
				function(result:UserResult):void {
					trace(sequence.step,"User:",JSON.stringify(result.user));
					trace(sequence.step,"Enter room");
					room = connect.getRoom(meetingroom);
					room.enter(sequence.next);
				},
				function(result:Result):void {
					room.fetchActivePods("FtStage",sequence.next);
				},
				function(result:ArrayResult):void {
					var videoPodID:String = result.array[0];
					room.fetchMeetingObject(videoPodID,PodType.VIDEO,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					videoObject = result.meetingObject;
					videoObject.sync = onSync;
					videoObject.serverCall("createNewStream",[room.userID],sequence.next);
				}
			);
		}
		
		private function gotSelfVideo():void {
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					room.fetchMeetingStream(videoObject.data[room.userID].streamId,LiveStream.PUBLISH,sequence.next);
				},
				function(result:MeetingStreamResult):void {
					var videoStream:IMeetingStream= result.stream;
					if(videoStream.stream) {
						videoStream.stream.receiveAudio(false);
						videoStream.stream.receiveVideo(false);
					}
					camera = Camera.getCamera();
					camera.setMode(320,240,12);
					videoStream.stream.attachCamera(camera);
				}
			);
		}
		
		private function stopVideo(id:String):void {
			trace("Stop video");
			var video:Video = videoContainer.getChildByName("video"+id) as Video;
			if(video) {
				videoContainer.removeChild(video);
				video.attachNetStream(null);
				room.closeNetStream(id);
				resetLayout();
			}
		}

		private function startVideo(id:String):void {
			if(id==room.userID) {
				gotSelfVideo();
			}
			
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					room.fetchMeetingStream(videoObject.data[id].streamId,LiveStream.PLAY,sequence.next);
				},
				function(result:MeetingStreamResult):void {
					videoStream = result.stream;
					videoStream.stream.receiveAudio(false);
					videoStream.stream.receiveVideo(true);
					trace(sequence.step,"Stream fetched");
					trace(sequence.step,"Start video");
					var video:Video = videoContainer.getChildByName("video"+id) as Video;
					if(!video) {
						video = new Video(VIDEO_WIDTH,VIDEO_HEIGHT);
						video.smoothing = true;
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
		
		private function onSync(e:SyncEvent):void {
			var changeList:Array = e?e.changeList:null;
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