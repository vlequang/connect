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
	import com.synco.utils.SyncoUtil;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.SyncEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Video;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import test.common.Test;
	
	[SWF(backgroundColor="0xcccccc" , width="1024" , height="768")]
	public class Test_pdfshare extends Test
	{
		private var pdfContainer:Sprite = new Sprite();
		private var loaders:Array = [];
		private var xmlLayout:XML;
		private var connect:Connect;
		private var pdfShareInfo:IMeetingObject;
		private var contentPath:String;
		private var loaderCount:int= 0;
		
		public function Test_pdfshare()
		{
			description = "View a PDF shared in the Share Pod";
		}
		
		override protected function init():void {
			var room:LiveRoom;
			var sequence:Sequence = new Sequence();
			var activeLayout:Object;
			var ctID:String;
			var index:int=0;
			var array:Array;
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
					room.fetchActiveSharePods("document",sequence.next);
				},
				function(result:ArrayResult):void {
					array = result.array;
					sequence.next();
				},
				function():void {
					if(index<array.length)
						room.fetchContent(array[index],sequence.next);
					else {
						trace("No pdf found");
						validate(false);
					}
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
					else {
						index++;
						sequence.jump(-1);
						SyncoUtil.callAsync(sequence.next);
					}
				},
				function(e:Event):void {
					var loader:URLLoader = e.currentTarget as URLLoader;
					xmlLayout = new XML(loader.data);
					room.fetchMeetingObject(ctID,PodType.PDF,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					pdfShareInfo = result.meetingObject;
					pdfShareInfo.sync = syncPDF;
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
			
			addChildAt(pdfContainer,0);
			
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
	}
}