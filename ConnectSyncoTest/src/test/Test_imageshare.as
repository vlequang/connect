package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.ConnectionResult;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.synco.result.ArrayResult;
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.media.Video;
	import flash.net.URLRequest;
	
	import test.common.Test;
	
//	[SWF(backgroundColor="0x000000" , width="1024" , height="768")]
	public class Test_imageshare extends Test
	{
		private var videoContainer:Sprite = new Sprite();
		private static const VIDEO_WIDTH:int = 320,VIDEO_HEIGHT:int = 240;
		
		public function Test_imageshare()
		{
			description = "View a shared image in the share pod";
		}
		
		override protected function init():void {
			var connect:Connect;
			var room:LiveRoom;
			var sequence:Sequence = new Sequence();
			var activeLayout:Object;
			var screenShareID:String;
			var path:String;
			var idsToTry:Array;
			var imageShareInfo:IMeetingObject;
			var loader:Loader;
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
					if(result.success && result.data.shareType=='document' && result.data.documentDescriptor.theType=='image') {
						path = result.data.documentDescriptor.theUrl;
						loader = new Loader();
						loader.contentLoaderInfo.addEventListener(Event.COMPLETE,sequence.next);
						loader.load(new URLRequest(connect.session.url + path));
					}
					else {
						sequence.jump(-1);
						sequence.next();
					}
				},
				function(e:Event):void {
					addChildAt(loader,0);
				}
			);
		}
	}
}