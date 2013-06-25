package com.adobe.connect.synco.content
{
	import com.adobe.connect.synco.login.HTTPLoader;
	import com.adobe.connect.synco.login.ImageLoader;
	import com.adobe.connect.synco.login.Session;
	import com.adobe.connect.synco.results.ImageResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.adobe.connect.synco.results.URLLoaderResult;
	import com.synco.result.DataResult;
	import com.synco.script.Sequence;
	
	import flash.net.URLVariables;
	import flash.utils.ByteArray;

	public class ContentManager
	{
		private var session:Session;
		
		public function ContentManager(session:Session)
		{
			this.session = session;
		}
		
		public function getScoID(name:String,callback:Function):void {
			HTTPLoader.get(session.url+"/"+name,{ mode:"xml" },
				function(result:URLLoaderResult):void {
					var scoID:String = parse(result.text);
					callback(new DataResult(scoID));
				});
		}
		
		public function deleteSco(scoID:String,callback:Function):void {
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					session.fetchSession(sequence.next);
				},
				function(result:SessionResult):void {
					HTTPLoader.get(session.url+"/api/xml", { 
						action:"sco-delete",
						"sco-id":scoID,
						session:result.sessionID
					},
					sequence.next);
				},
				function(result:URLLoaderResult):void {
					callback(result);
				}
			);
		}
		
		public function createSco(folderID:String,name:String,urlPath:String,callback:Function):void {
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					session.fetchSession(sequence.next);
				},
				function(result:SessionResult):void {
					HTTPLoader.get(session.url+"/api/xml", { 
						action:"sco-update",
						"folder-id":folderID,
						name:name,
						"url-path":urlPath,
						session:result.sessionID
					},
					sequence.next);
				},
				function(result:URLLoaderResult):void {
					if(result.success) {
						var xml:XML = new XML(result.text);
						callback(new DataResult(xml.sco.@["sco-id"]));
					}
					else
						callback(result);
				}
			);
		}
		
		public function upload(url:String,scoID:String,filename:String,bytes:ByteArray,callback:Function):void {
			HTTPLoader.upload(session.url+"/api/xml", {
				action: "sco-upload",
				"sco-id": scoID
			}, filename, bytes,
			callback);
		}
		
		public function getScoStatus(scoID:String,callback:Function):void {
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					session.fetchSession(sequence.next);
				},
				function(result:SessionResult):void {
					HTTPLoader.get(session.url+"/api/xml", {
						action: "sco-info",
						"sco-id": scoID,
						session: result.sessionID
					},sequence.next);
				},
				function(result:URLLoaderResult):void {
					if(result.success) {
						var xml:XML = new XML(result.text);
						callback(new DataResult(xml.status.@code));
					}
					else
						callback(result);
				}
			);
		}
		
		private function parse(html:String):String {
			var value:String = null;
			try {
				var tag:String = 'sco-id="';
				var startIndex:int = html.indexOf(tag);
				if(startIndex>=0) {
					var endIndex:int = Math.min(uint(html.indexOf("&",startIndex+tag.length)),uint(html.indexOf(";",startIndex+tag.length)),uint(html.indexOf('"',startIndex+tag.length)),uint(html.indexOf("'",startIndex+tag.length)));
					value = html.substring(startIndex+tag.length,endIndex);
				}
			}
			catch(e:Error) {
				trace(e);
			}
			return value;
		}		
	}
}