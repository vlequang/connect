package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.graphics.WhiteboardShape;
	import com.adobe.connect.synco.graphics.WhiteboardUtil;
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
	import com.synco.utils.SyncoUtil;
	
	import flash.display.Sprite;
	import flash.events.SyncEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import test.common.Test;
	
	public class Test15_whiteboard extends Test
	{
		private var overlay:Sprite = new Sprite();
		private var whiteboardObj:IMeetingObject;
		private var whiteboardUtil:WhiteboardUtil = new WhiteboardUtil();
		private var nativeWidth:int, nativeHeight:int;
		private var graphicShapes:Object = {};
		
		public function Test15_whiteboard()
		{
			overlay.mouseChildren = overlay.mouseEnabled = false;
			var sequence:Sequence = new Sequence();
			var connect:Connect;
			var room:LiveRoom;
			var wbinfo:Object;
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
					trace(sequence.step,"login");
					connect.session.login(username,password,null,sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"enter room");
					room = connect.getRoom(meetingroom);
					room.enter(sequence.next);
				},
				function(result:ConnectionResult):void {
					trace(sequence.step,"Connected to",room.netConnection.uri);
					findFirstWhiteboard(room,sequence.next);
				},
				function(result:DataResult):void {
					if(result.success)
						room.fetchContent(result.text,sequence.next);
				},
				function(result:DataResult):void {
					wbinfo = result.data;
					room.fetchMeetingObject(wbinfo.ctID,PodType.WHITEBOARD,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					nativeWidth = result.meetingObject.data.nativeWidth;
					nativeHeight = result.meetingObject.data.nativeHeight;
					room.fetchMeetingObject(wbinfo.ctID,PodType.CONTENTWHITEBOARD,[result.meetingObject.data.currentPage],sequence.next);
				},
				function(result:MeetingObjectResult):void {
					whiteboardObj = result.meetingObject;
					addChild(overlay);
					
					whiteboardObj.sync = onSync;
				}
			);
		}
		
		private function getShape(shape:Object):WhiteboardShape {
			var wbShape:WhiteboardShape = graphicShapes[shape.z];
			if(!wbShape) {
				graphicShapes[shape.z] = wbShape = new WhiteboardShape();
				whiteboardUtil.defineShape(shape,wbShape);
			}
			return wbShape;
		}
		
		private function onSync(e:SyncEvent):void {
			var changeList:Array = e?e.changeList:null;
			trace(JSON.stringify(changeList,null,"\t"));
			
			var changes:Object = null;
			if(changeList) {
				changes = {};
				for each(var change:Object in changeList) {
					if(change.code=="change")
						changes[change.name] = change;
					else if(change.code=="delete") {
						if(overlay.getChildByName(change.name))
							overlay.removeChild(overlay.getChildByName(change.name));
					}
				}
			}
			
			var shape:Object;
			for each(shape in whiteboardObj.data) {
				if(shape.hasOwnProperty("type") && (!changes || changes[shape.z])) {
					getShape(shape).setPosition(shape.x,shape.y);
					switch(shape.type) {
						case "pencil":
							whiteboardUtil.pencilShape(shape,getShape(shape));
							whiteboardUtil.textShape(shape,getShape(shape));
							break;
						case "rectangle":
							whiteboardUtil.rectangleShape(shape,getShape(shape));
							whiteboardUtil.textShape(shape,getShape(shape));
							break;
						case "text":
							whiteboardUtil.textShape(shape,getShape(shape));
							break;
						default:
							trace(shape.type);
							break;
					}
				}
			}
			
			var shapes:Array = [];
			for each(var wbShape:WhiteboardShape in graphicShapes) {
				shapes.push(wbShape);
			}
			shapes = shapes.sortOn("id",Array.NUMERIC);
			for each(wbShape in shapes) {
				wbShape.draw(overlay);
			}
			
			var scale:Number = Math.min(stage.stageWidth/800,stage.stageHeight/600);
			overlay.scaleX = overlay.scaleY = scale;
		}
		

		private function findFirstWhiteboard(room:LiveRoom,callback:Function):void {
			var whiteboardData:Object;
			var id:String;
			var idsToTry:Array = [];
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					room.fetchActivePods("FtContent",sequence.next);
				},
				function(result:ArrayResult):void {
					idsToTry = result.array;
					sequence.next();
				},
				function():void {
					if(!idsToTry.length) {
						callback(new DataResult(null));
						return;
					}
					id = idsToTry.pop();
					room.fetchContent(id,sequence.next);
				},
				function(result:DataResult):void {
					var info:Object = result.data;
					if(!info || info.shareType!="wb") {
						sequence.jump(-1);
						SyncoUtil.callAsync(sequence.next);
					}
					else {
						callback(new DataResult(id));
					}
				}
			);
		}
	}
}
