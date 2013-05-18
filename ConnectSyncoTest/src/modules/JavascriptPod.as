package modules
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.graphics.WhiteboardShape;
	import com.adobe.connect.synco.graphics.WhiteboardUtil;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.interfaces.IMeetingStream;
	import com.adobe.connect.synco.javascript.JavascriptEvent;
	import com.adobe.connect.synco.javascript.JavascriptInterface;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.live.LiveStream;
	import com.adobe.connect.synco.pods.Pod;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.synco.results.MeetingStreamResult;
	import com.synco.result.ArrayResult;
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	import com.synco.utils.SyncoUtil;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.SyncEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Video;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import by.blooddy.crypto.Base64;
	import by.blooddy.crypto.MD5;
	import by.blooddy.crypto.image.JPEGEncoder;
	import by.blooddy.crypto.image.PNGEncoder;
	
	
	[SWF(width="100",height="100")]
	public class JavascriptPod extends Pod
	{
		private static const VIDEO_WIDTH:int = 480,VIDEO_HEIGHT:int = 300;

		private var videoContainer:Sprite = new Sprite(), screenshareContainer:Sprite = new Sprite();
		private var bmpd:BitmapData = new BitmapData(VIDEO_WIDTH,VIDEO_HEIGHT,false);
		private var srcCache:Object= {};
		private var liveRoom:LiveRoom, chatObj:IMeetingObject;
		private var sharedObject:SharedObject ;
		private var whiteboardObj:IMeetingObject, videoObject:IMeetingObject, screenShareObject:IMeetingObject;
		private var videoStream:IMeetingStream, screenStream:IMeetingStream;
		private var whiteboardUtil:WhiteboardUtil = new WhiteboardUtil();
		private var screenStreamID:String;
		
		private var pdfContainer:Sprite = new Sprite();
		private var loaders:Array = [];
		private var xmlLayout:XML;
		private var connect:Connect;
		private var pdfShareInfo:IMeetingObject;
		private var contentPath:String;
		private var loaderCount:int= 0;
		
		private var audioObject:IMeetingObject;
		private var audioStream:IMeetingStream;
		private var audioStreamId:String;
		
		[Embed(source="connectlogo.png")]
		private var ConnectLogo:Class;
		
		
		private var javascript:JavascriptInterface = new JavascriptInterface();
		public function JavascriptPod()
		{
			graphics.beginBitmapFill(new ConnectLogo().bitmapData);
			graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
			graphics.endFill();
			sharedObject = SharedObject.getLocal("connectsynco");
			javascript.initialize(
				function(result:Result):void {
					if(result.success) {
						javascript.addEventListener(JavascriptEvent.JSEVENT,handleJavascript);
						trace("Ready!");
						/*
						if(sharedObject.data.connectRoom) {
							javascript.sendToJavascript({action:"roomEntered",room:sharedObject.data.connectRoom});
							init(sharedObject.data.connectRoom);
						}*/
					}
				}
			);
		}
		
		private function handleJavascript(e:JavascriptEvent):void {
			switch(e.action) {
				case "chat":
					chatObj.serverCall("sendMessage",[0,e.obj.message,-1,'Black',-1]);
					break;
				case "enter":
					init(e.obj.room);
					sharedObject.setProperty("connectRoom",e.obj.room);
					break;
				case "exit":
					sharedObject.setProperty("connectRoom",null);
					ExternalInterface.call("function(){top.location.reload(true);}");
					break;
				case "hi":
					var src:String;
					src = getSrc(videoContainer,"jpeg");
					if(src)
						javascript.sendToJavascript({action:'video',src:src});
					src = getSrc(screenshareContainer,"jpeg");
					if(src) {
						javascript.sendToJavascript({action:'screenshare',src:src});
					}
					else {
						src = getSrc(pdfContainer,"png");
						if(src) {
							javascript.sendToJavascript({action:'screenshare',src:src});
						}
					}
					break;
			}
		}
		
		private function getSrc(container:Sprite,encoding:String):String {
			bmpd.fillRect(bmpd.rect,0);
			bmpd.draw(container,new Matrix(container.scaleX,0,0,container.scaleY),null,null,null,false);
			/*
			var bytes:ByteArray = PNGEncoder.encode(bmpd);
			var md5:String = MD5.hashBytes(bytes);
			if(md5==videoMD5) {
				return null;
			}
			videoMD5 = md5;
			var b64:String = Base64.encode(bytes);
			var src:String = "data:image/png;base64,"+b64;
			*/
			var bytes:ByteArray = encoding=="jpeg"?JPEGEncoder.encode(bmpd,90):
									encoding=="png"?PNGEncoder.encode(bmpd):
									null;
			if(!bytes)
				return null;
			var md5:String = MD5.hashBytes(bytes);
			if(md5==srcCache[container.name]) {
				return null;
			}
			srcCache[container.name] = md5;
			var b64:String = Base64.encode(bytes);
			var src:String = encoding=="jpeg"?"data:image/jpeg;base64,"+b64:
							encoding=="png"?"data:image/png;base64,"+b64:
							null;
			return src;
		}
		
		private function init(room:String):void {
			var sequence:Sequence = new Sequence();
			var wbinfo:Object;
			var nativeWidth:int,nativeHeight:int;

			var activeLayout:Object;
			var ctID:String;
			
			var loginSteps:Function,
				audioSteps:Function,
				chatSteps:Function,
				videoSteps:Function,
				screenshareSteps:Function,
				whiteboardSteps:Function;
			
			sequence.run(
				loginSteps = function():void {
					trace(sequence.step,"fetch connect");
					Connect.fetchConnect(serverURL,null,sequence.next);
				},
				function(result:ConnectResult):void {
					trace(sequence.step,"Connect Version:",result.version);
					connect = result.connect;
					liveRoom = connect.getRoom(room);
					liveRoom.enter(sequence.next);
				},
				audioSteps = function(result:Result):void {
					if(!result || !result.success) {
						javascript.sendToJavascript({action:"loginRequired"});
						return;
					}
					liveRoom.fetchMeetingObject(null,PodType.UNIVOICE,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					audioObject = result.meetingObject;
					audioObject.sync = onAudioSync;
					SyncoUtil.callAsync(sequence.next);
				},
				chatSteps = function(result:Result):void {
					liveRoom.fetchActivePods("FtChat",sequence.next);
				},
				function(result:ArrayResult):void {
					var podIDs:Array = result.array;
					trace(sequence.step,"Get Chat pod");
					var chatPodID:String = podIDs[0];
					liveRoom.fetchMeetingObject(chatPodID,PodType.CHATMESSAGES,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					chatObj = result.meetingObject;
					trace(sequence.step,"Register message events");
					chatObj.addCallback("message",receiveMessage);
					chatObj.addCallback("clearHistory",clearHistory);
					trace(sequence.step,"Get chat history");
					chatObj.serverCall("getHistory",[],sequence.next);
				},
				function(result:DataResult):void {
					receiveMessage.apply(null,result.data.history);
					sequence.next();
				},
//				videoSteps = function(result:Result):void {
//					javascript.sendToJavascript({action:"updateVideo",room:room});
//					sequence.next();
//				},
//				screenshareSteps = function(result:Result):void {
//					javascript.sendToJavascript({action:"updateScreenShare",room:room});
//					sequence.next();
//				},
				whiteboardSteps = function(result:Result):void {
					findFirstWhiteboard(liveRoom,sequence.next);
				},
				function(result:DataResult):void {
					if(result.success)
						liveRoom.fetchContent(result.text,sequence.next);
					else {
						sequence.jump(videoSteps);
						sequence.next();
					}
				},
				function(result:DataResult):void {
					wbinfo = result.data;
					liveRoom.fetchMeetingObject(wbinfo.ctID,PodType.WHITEBOARD,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					if(result.meetingObject.data) {
						nativeWidth = result.meetingObject.data.nativeWidth;
						nativeHeight = result.meetingObject.data.nativeHeight;
						liveRoom.fetchMeetingObject(wbinfo.ctID,PodType.CONTENTWHITEBOARD,[result.meetingObject.data.currentPage],sequence.next);
					}
				},
				function(result:MeetingObjectResult):void {
					whiteboardObj = result.meetingObject;
					whiteboardObj.sync = onWhiteboardSync;
					sequence.next();
				},
				videoSteps = function(result:Result):void {
					liveRoom.fetchActivePods("FtStage",sequence.next);
				},
				function(result:ArrayResult):void {
					if(!result.success || !result.array.length) {
						sequence.jump(screenshareSteps);
						sequence.next();
					}
					else {
						var videoPodID:String = result.array[0];
						liveRoom.fetchMeetingObject(videoPodID,PodType.VIDEO,null,sequence.next);
					}
				},
				function(result:MeetingObjectResult):void {
					videoObject = result.meetingObject;
					videoObject.sync = onVideoSync;
					sequence.next();
				},
				screenshareSteps = function(result:MeetingObjectResult):void {
					findFirstScreenshare(liveRoom,sequence.next);
				},
				function(result:DataResult):void {
					liveRoom.fetchContent(result.text,sequence.next);
				},
				function(result:DataResult):void {
					if(result.success) {
						screenStreamID = result.data.screenDescriptor.streamID;
						liveRoom.fetchMeetingObject(result.data.ctID,PodType.SCREENSHARE,null,sequence.next);
					}
					else {
						SyncoUtil.callAsync(sequence.next);
					}
				},
				function(result:MeetingObjectResult):void {
					if(result) {
						screenShareObject = result.meetingObject;
						liveRoom.fetchMeetingStream(screenStreamID,LiveStream.PLAY,sequence.next);
					}
					else {
						SyncoUtil.callAsync(sequence.next);
					}
				},
				function(result:MeetingStreamResult):void {
					if(result) {
						screenStream = result.stream;
						var video:Video = screenshareContainer.getChildByName(screenStream.id) as Video;
						if(!video) {
							var w:int = screenShareObject.data.w;
							var h:int = screenShareObject.data.h;
							var scale:Number = Math.min(VIDEO_WIDTH/w,VIDEO_HEIGHT/h);
							video = new Video(w*scale,h*scale);
							video.smoothing = true;
							video.name = screenStream.id;
							screenshareContainer.addChild(video);
							resetLayout(screenshareContainer);
						}
						video.attachNetStream(screenStream.stream);
						SyncoUtil.callAsync(sequence.next);
					}
					else {
						SyncoUtil.callAsync(sequence.next);
					}
				},
				function():void {
					liveRoom.fetchActiveSharePods("document",sequence.next);
				},
				function(result:ArrayResult):void {
					liveRoom.fetchContent(result.array[0],sequence.next);
				},
				function(result:DataResult):void {
					trace(JSON.stringify(result.data,null,'\t'));
					if(result.success && result.data.documentDescriptor.theType=='pdf2swf') {
						contentPath = result.data.documentDescriptor.contentOutputPath;
						ctID = result.data.ctID;
						var url:String = connect.session.url+contentPath+"data/layout.xml";
						var loader:URLLoader = new URLLoader();
						loader.addEventListener(Event.COMPLETE,sequence.next);
						loader.load(new URLRequest(url));
					}
				},
				function(e:Event):void {
					var loader:URLLoader = e.currentTarget as URLLoader;
					xmlLayout = new XML(loader.data);
					liveRoom.fetchMeetingObject(ctID,PodType.PDF,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					pdfShareInfo = result.meetingObject;
					pdfShareInfo.sync = syncPDF;
				}
			);
		}
	
		private function onVideoSync(e:SyncEvent):void {
			var changeList:Array = e ? e.changeList : null;
			var changes:Object = null;
			if(changeList) {
				changes = {};
				for each(var change:Object in changeList) {
					if(change.code=="change") {
						changes[change.name] = change;
					}
					else if(change.code=="delete") {
						stopVideo(change.name,videoContainer);
					}
				}
			}
			
			for(var i:String in videoObject.data) {
				if(!changes || changes[i]) {
					startVideo(i);
				}
			}
		}

		private function stopVideo(id:String,container:Sprite):void {
			var video:Video = container.getChildByName(id) as Video;
			if(video) {
				container.removeChild(video);
				video.attachNetStream(null);
				liveRoom.closeNetStream(id);
				resetLayout(container);
			}
		}
		
		private function startVideo(id:String):void {
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					liveRoom.fetchMeetingStream(videoObject.data[id].streamId,LiveStream.PLAY,sequence.next);
				},
				function(result:MeetingStreamResult):void {
					videoStream = result.stream;
					var video:Video = videoContainer.getChildByName(id) as Video;
					if(!video) {
						video = new Video(VIDEO_WIDTH,VIDEO_HEIGHT);
						video.name = id;
						videoContainer.addChild(video);
						resetLayout(videoContainer);
					}
					video.attachNetStream(videoStream.stream);
				}
			);
		}		
		
		private function resetLayout(container:Sprite):void {
			var videoCount:int= container.numChildren;
			//	find best configuration
			var bestCols:int;
			var bestRows:int;
			var bestScale:Number = 0;
			for(var rows:int=1;rows<=videoCount;rows++) {
				var cols:int = videoCount/rows;
				var totalWidth:int = cols*VIDEO_WIDTH;
				var totalHeight:int = rows*VIDEO_HEIGHT;
				var scale:Number = Math.min(VIDEO_WIDTH/totalWidth,VIDEO_HEIGHT/totalHeight);
				if(scale>bestScale) {
					bestCols = cols;
					bestScale = scale;
				}
			}
			bestRows = videoCount/bestCols;
			for(var i:int=0;i<videoCount;i++) {
				var child:DisplayObject = container.getChildAt(i);
				child.x = (i%bestCols)*VIDEO_WIDTH + (VIDEO_WIDTH-child.width)/2;
				child.y = int(i/bestCols)*VIDEO_HEIGHT + (VIDEO_HEIGHT-child.height)/2;
			}
			container.scaleX = container.scaleY = bestScale;
			container.x = (stage.stageWidth-bestCols*VIDEO_WIDTH*bestScale)/2
			container.y = (stage.stageHeight-bestRows*VIDEO_HEIGHT*bestScale)/2
		}		

		private function onWhiteboardSync(e:SyncEvent):void {
			var changeList:Array = e ? e.changeList : null;
			var shapes:Array = [];
			var shape:Object,wbShape:WhiteboardShape;

			var changes:Object = null;
			if(changeList) {
				changes = {};
				for each(var change:Object in changeList) {
					if(change.code=="change")
						changes[change.name] = change;
					else if(change.code=="delete") {
						shapes.push({id:change.name,"delete":true});
					}
				}
			}

			for each (shape in whiteboardObj.data) {
				if(shape.hasOwnProperty("type") && (!changes || changes[shape.z])) {
					wbShape = new WhiteboardShape();
					whiteboardUtil.defineShape(shape,wbShape);
					
					wbShape.setPosition(shape.x,shape.y);
					switch(shape.type) {
						case "pencil":
							whiteboardUtil.pencilShape(shape,wbShape);
							//whiteboardUtil.textShape(shape,wbShape);
							break;
						case "rectangle":
							whiteboardUtil.rectangleShape(shape,wbShape);
							//whiteboardUtil.textShape(shape,wbShape);
							break;
						case "text":
							//whiteboardUtil.textShape(shape,wbShape);
							break;
						default:
							trace(shape.type);
							break;
					}
					shapes.push(wbShape.toObject());
				}
			}
			shapes = shapes.sortOn('depth',Array.NUMERIC);
			javascript.sendToJavascript({action:"whiteboard",shapes:shapes});
			
//			var scale:Number = Math.min(stage.stageWidth/800,stage.stageHeight/600);
//			overlay.scaleX = overlay.scaleY = scale;
		}
		
		private function clearHistory():void {
			javascript.sendToJavascript({action:"clearHistory"});
		}
		
		private function receiveMessage(...messages):void {
			javascript.sendToJavascript({action:"receiveMessages",messages:messages});
		}
		
		private function findFirstWhiteboard(room:LiveRoom,callback:Function):void {
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
		
		private function findFirstScreenshare(room:LiveRoom,callback:Function):void {
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
					if(!info || info.shareType!="screen") {
						sequence.jump(-1);
						SyncoUtil.callAsync(sequence.next);
					}
					else {
						callback(new DataResult(id));
					}
				}
			);
		}
		
		private function syncPDF(e:SyncEvent):void {
			var mementoObj:Object;
			mementoObj = parseMemento(pdfShareInfo.data.memento);
			trace(JSON.stringify(mementoObj,null,'\t'));
			var topPageIndex:int = mementoObj.tPgNum;
			var bottomPageIndex:int = mementoObj.bPgNum;
			var numPages:int = bottomPageIndex-topPageIndex+1;
			var rects:Vector.<Rectangle> = new Vector.<Rectangle>(numPages);
			var sprites:Vector.<Sprite> = new Vector.<Sprite>(numPages);
			var rotn:int = mementoObj.rotn;
			var ypos:int = 0;
			while(pdfContainer.numChildren)
				pdfContainer.removeChildAt(0);
			//			var leftOffset:Number = mementoObj.tLOff||0;		//	ignore those
			//			var rightOffset:Number = mementoObj.tROff||0;
			for(var i:int=0;i<sprites.length;i++) {
				sprites[i] =  new Sprite();
				pdfContainer.addChild(sprites[i]);
				sprites[i].graphics.drawRect(0,0,xmlLayout.Pages.Page[topPageIndex+i].@xMax,xmlLayout.Pages.Page[topPageIndex+i].@yMax);
				sprites[i].rotation = rotn;
				var rect:Rectangle = sprites[i].getRect(pdfContainer);
				sprites[i].x = -rect.x;
				sprites[i].y = -rect.y + ypos;
				rects[i] = sprites[i].getRect(pdfContainer);
				ypos += rects[i].height;
			}
			var scale:Number = mementoObj.zmR;
			
			pdfContainer.scaleX = pdfContainer.scaleY = scale;
			var topLeft:Point = new Point(), bottomRight:Point = new Point();
			topLeft.x = rects[0].width * (mementoObj.tLPct||0);
			topLeft.y = rects[0].height * (mementoObj.tPgPct||0);
			bottomRight.x = rects[rects.length-1].width * (mementoObj.tRPct||1);
			bottomRight.y = (topPageIndex!=bottomPageIndex ? rects[0].height : 0)
				+ rects[rects.length-1].height * (mementoObj.bPgPct||1);
			pdfContainer.scrollRect = new Rectangle(topLeft.x,topLeft.y,(bottomRight.x-topLeft.x),(bottomRight.y-topLeft.y));
			
			//addChildAt(pdfContainer,0);
			
			for(i=0;i<numPages;i++) {
				var loader:Loader = loadPage(topPageIndex+i);
				sprites[i].addChild(loader);
			}
		}
		
		private function loadPage(page:int):Loader {
			var loader:Loader = loaders[page];
			if(!loader) {
				loaders[page] = loader = new Loader();
				var fileName:String = xmlLayout.Pages.Page[page].text();
				var url:String = connect.session.url+contentPath+"data/"+fileName;
				loaderCount++;
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE,onLoaded);
				loader.load(new URLRequest(url));
			}
			return loader;
		}
		
		private function onLoaded(e:Event):void {
			loaderCount--;
			if(loaderCount==0) {
				var totalPages:int = xmlLayout.Pages.@Number;
				var mementoObj:Object = parseMemento(pdfShareInfo.data.memento);
				var topPageIndex:int = mementoObj.tPgNum;
				
				var closest:int = -1;
				for(var i:int=0;i<totalPages;i++) {
					if(!loaders[i]) {
						if(closest==-1 || Math.abs(topPageIndex-closest)>Math.abs(topPageIndex-i)) {
							closest = i;
						}
					}
				}
				if(closest!=-1)
					loadPage(closest);
			}
		}
		
		private function parseMemento(memento:String):Object {
			var mentInfo:Object = {};
			if(memento) {
				var mentos:Array = memento.split("|");
				for(var i:int=0;i<mentos.length;i++) {
					if(mentos[i]) {
						mentos[i] = mentos[i].split("-");
						mentInfo[mentos[i][0]] = mentos[i][1];
					}
				}
			}
			return mentInfo;
		}
		
		private function startAudio(streamId:String):void {
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					liveRoom.fetchMeetingStream(streamId,LiveStream.PLAY,sequence.next);
				},
				function(result:MeetingStreamResult):void {
					audioStream = result.stream;
					audioStream.stream.receiveAudio(true);
					audioStream.stream.receiveVideo(false);
					trace(sequence.step,"Stream fetched");
					trace(sequence.step,"Start audio");
				}
			);
		}
		
		private function stopAudio(id:String):void {
			trace("Stop audio");
			liveRoom.closeNetStream(id);
		}
		
		private function onAudioSync(e:SyncEvent):void {
			
			var currentStreamId:String = audioObject.data.state=='disconnected' ? null : audioObject.data.streamId;
			if(audioStreamId != currentStreamId) {
				if(audioStreamId) {
					stopAudio(audioStreamId);
					audioStreamId = null;
				}
				if(currentStreamId) {
					audioStreamId = currentStreamId;
					startAudio(audioStreamId);
				}
			}
		}
	}
}