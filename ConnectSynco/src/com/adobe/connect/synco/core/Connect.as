package com.adobe.connect.synco.core
{
	import com.adobe.connect.synco.content.ContentManager;
	import com.adobe.connect.synco.javascript.JavascriptInterface;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.login.HTTPLoader;
	import com.adobe.connect.synco.login.Session;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.ConnectionResult;
	import com.adobe.connect.synco.results.JavascriptInterfaceResult;
	import com.adobe.connect.synco.results.RoomsResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.adobe.connect.synco.results.URLLoaderResult;
	import com.adobe.connect.synco.results.XMLResult;
	import com.synco.result.DataResult;
	import com.synco.script.Sequence;
	import com.synco.utils.SyncoUtil;
	
	import flash.external.ExternalInterface;
	
	public class Connect
	{
		static private const connectObjects:Object = {};
		public const session:Session = new Session();
		public const contentManager:ContentManager = new ContentManager(session);
		private var rooms:Object = {};
		
		public function Connect()
		{
		}
		
		static public function fetchConnect(serverURL:String,sessionID:String,callback:Function):void {
			var connect:Connect = connectObjects[serverURL];
			if(!connect) {
				connectObjects[serverURL] = connect = new Connect();
				connect.session.url = serverURL;
			}
			connect.session.fetchVersion(sessionID,
				function(result:DataResult):void {
					if(result.success) {
						callback(new ConnectResult(connect,result.text));
					}
					else {
						callback(new ConnectResult(null));
					}
				});
		}
		
		public function getRoom(meetingroom:String):LiveRoom {
			var room:LiveRoom = rooms[meetingroom] || (rooms[meetingroom] = new LiveRoom(meetingroom,session));
			return room;
		}
		
		public function listRooms(callback:Function):void {
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					session.fetchSession(sequence.next);
				},
				function(result:SessionResult):void {
					HTTPLoader.get(session.url+"/api/xml",
						{
							action:"report-my-meetings"
						},
						function(result:URLLoaderResult):void {
							var xml:XML = new XML(result.text);
							var rooms:Array = [];
							for each(var meeting:XML in xml["my-meetings"].meeting) {
								rooms.push(meeting["url-path"].toString().split("/")[1]);
							}
							callback(new RoomsResult(rooms));
						});
				});
		}
		
		public function callAPI(params:Object,callback:Function):void {
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					session.fetchSession(sequence.next);
				},
				function(result:SessionResult):void {
					HTTPLoader.get(session.url+"/api/xml",
						params,
						function(result:URLLoaderResult):void {
							var xml:XML = new XML(result.text);
							callback(new XMLResult(xml));
						});
				});
		}
	}
}