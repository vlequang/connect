package com.adobe.connect.synco.login
{
	import com.adobe.connect.synco.results.ConnectionResult;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.net.NetConnection;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.utils.object_proxy;

	public class ConnectionFetch
	{
		private static const TIMEOUT:int = 7000;
		private static const MAXCONNECTION:int = 1;
		
		private var connectionTries:Array;
		private var callback:Function;
		private var dispatcher:EventDispatcher = new EventDispatcher();
		private var pendingAttempts:int;
		private var connectToRecording:Boolean;
		private var _ticket:String;
		
		public function ConnectionFetch(url:String,sessionID:String,options:Object,callback:Function)
		{
			this.callback = callback;
			var request:URLRequest = new URLRequest(url);
			request.data = new URLVariables();
			if(sessionID)
				request.data.session = sessionID;
			for(var o:String in options) {
				request.data[o] = options[o];
			}
			request.data["disclaimer-consent"]=true;
			delete request.data.session;

			var urlloader:URLLoader = new URLLoader();
			urlloader.addEventListener(Event.COMPLETE,
				function(e:Event):void {
//					trace(urlloader.data);
					e.currentTarget.removeEventListener(e.type,arguments.callee);
					var vars:URLVariables = parse(urlloader.data);
					connectionTries = getConnectionTries(vars);
					if(connectionTries) {
						tryConnections();
					}
					else {
						onConnectionsFailed();
					}
				});
			urlloader.addEventListener(IOErrorEvent.IO_ERROR,onConnectionsFailed);
			//trace(request.url+"?"+request.data);
			urlloader.load(request);
		}
		
		static public function getConnection(url:String,sessionID:String,options:Object,callback:Function):void {
			new ConnectionFetch(url,sessionID,options,callback);
		}
		
		private function onConnectionsFailed(...params):void {
			callback(new ConnectionResult(null));
		}
		
		private function tryConnections():void {
			for(var i:int=0;i<MAXCONNECTION;i++) {
				tryNewConnection();
			}
		}
		
		private function tryNewConnection():Boolean {
			if(!connectionTries.length) {
				return false;
			}
			pendingAttempts++;
			var params:Array = connectionTries.shift();
			var netConnection:NetConnection = new NetConnection();
			var connectSuccess:Boolean = false;
			var loginInfo:Object = null;
			
			var checkConnection:Function = function(obj:Object):void {
				if(obj is NetStatusEvent && obj.info.code=="NetConnection.Connect.Success") {
					netConnection.removeEventListener(NetStatusEvent.NET_STATUS,checkConnection);
					connectSuccess = true;
				}
				else if(obj.hasOwnProperty('command') && obj.command=="accepted") {
					loginInfo = obj;
				}
				else if(obj.hasOwnProperty('command') && obj.command=="tryNextOrigin") {
					timer.stop();
					if(!tryNewConnection()) {
						failConnection(netConnection);
					}
				}
				else if(obj.hasOwnProperty('command') && obj.command=="namedOrganizerViewer") {
					timer.stop();
				}
				else if(obj.hasOwnProperty('command') && obj.command=="wait") {
					timer.stop();
				}
				else if(obj.hasOwnProperty('command') && obj.command=="onHold") {
					timer.stop();
				}
				else if(obj.hasOwnProperty('command') && obj.command=="blocked") {
					netConnection.call("roomMgrCall", null, "requestEntry");		
					timer.stop();
				}
				else if(obj.hasOwnProperty('command') && obj.command=="guestsNoLongerAllowed") {
					netConnection.call("roomMgrCall", null, "requestEntry");		
					timer.stop();					
				}
				else if(obj is TimerEvent) {
					if(!tryNewConnection()) {
						failConnection(netConnection);
					}
				}
				else {
					failConnection(netConnection);
					return;
				}
				
				if(connectSuccess && loginInfo) {
					delete netConnection.client.loginHandler;
					timer.removeEventListener(TimerEvent.TIMER_COMPLETE,checkConnection);
					dispatcher.removeEventListener(Event.COMPLETE,onCloseConnection);
					timer.stop();
					connectionComplete(netConnection,loginInfo);
				}
			};
			
			var onCloseConnection:Function = function(e:Event):void {
				timer.removeEventListener(TimerEvent.TIMER_COMPLETE,checkConnection);
				dispatcher.removeEventListener(Event.COMPLETE,onCloseConnection);
				timer.stop();
				netConnection.removeEventListener(NetStatusEvent.NET_STATUS,checkConnection);
				cancelConnection(netConnection);
			}
			
			netConnection.client = {
				loginHandler:checkConnection,
				onError:checkConnection,
				ejected:checkConnection,
				areYouOk:checkConnection,
				archiveEdited:checkConnection,
				archiveRevertedToOriginal:checkConnection				
			};
			netConnection.addEventListener(NetStatusEvent.NET_STATUS,checkConnection);
			netConnection.connect.apply(netConnection,params);
			
			var timer:Timer = new Timer(TIMEOUT,1);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE,checkConnection);
			timer.start();
			
			dispatcher.addEventListener(Event.COMPLETE,onCloseConnection);
			return true;
		}
		
		private function failConnection(netConnection:NetConnection):void {
			pendingAttempts--;
			cancelConnection(netConnection);
			tryNewConnection();
			if(!connectionTries.length && !pendingAttempts) {
				onConnectionsFailed();
			}
		}
		
		private function cancelConnection(netConnection:NetConnection):void {
			if(netConnection.connected)
				netConnection.close();
			else {
				netConnection.addEventListener(NetStatusEvent.NET_STATUS,
					function(e:NetStatusEvent):void {
						e.currentTarget.removeEventListener(e.type,arguments.callee);
					});
			}
		}
		
		private function connectionComplete(netConnection:NetConnection,loginInfo:Object):void {
			callback(new ConnectionResult(netConnection,loginInfo,ticket));
			dispatcher.dispatchEvent(new Event(Event.COMPLETE));
		}
		
		public function get ticket():String {
			return _ticket;
		}
		
		private function getConnectionTries(vars:URLVariables):Array {
			_ticket = vars.ticket is Array?vars.ticket[0]:vars.ticket;
			if(!ticket)
				return null;
			
			connectToRecording = vars.isLive=="false";
			
			var connectionTries:Array = [];
			if(connectToRecording)
			{
				var conStringArray:Array = vars.conStrings.split(",");
				for each(var uri:String in conStringArray) {
					var connectionString:String = uri+"flvplayeras3app/"+vars.appInstance;
					connectionTries.push([connectionString,ticket,true]);
				}
			}
			else
			{
				var origins:Array = vars.origins.split(",");
				var protos:Array = vars.protos.split(",");
				var edges:Array = vars.edges.split(",");
				if(!edges.length)
					edges = [null];
				
				for each(var origin:String in origins) {
					for each(var edge:String in edges) {
						for each(var proto:String in protos) {
							var protoSplit:Array = proto.split(":");
							var uri_scheme:String = protoSplit[0];
							var port:String = protoSplit[1];
							var originURL:String = uri_scheme + "://" + origin + "/meetingas3app/" + vars.appInstance;
							if(edge) {
								connectionTries.push([uri_scheme+"://"+edge+":"+port+"/?"+originURL,ticket,"lan",Capabilities.version,false]);
							}
							else {
								connectionTries.push([originURL,vars.ticket is Array?vars.ticket[0]:vars.ticket,"lan",Capabilities.version,false]);
							}
						}
					}
				}
			}
			return connectionTries;
		}
				
		private function parse(html:String):URLVariables {
			var vars:URLVariables = null;
			try {
				var tag:String = "swfUrl=";
				var startIndex:int = html.indexOf(tag);
				var endIndex:int = Math.min(uint(html.indexOf("&",startIndex)),uint(html.indexOf(";",startIndex)),uint(html.indexOf('"',startIndex)),uint(html.indexOf("'",startIndex)));
				var varString:String = html.substring(startIndex+tag.length,endIndex);
				varString = unescape(varString);
				varString = varString.split("?")[1];
				vars = new URLVariables(varString);
				return vars;
			}
			catch(e:Error) {
				trace(e);
			}
			return vars;
		}		
	}
}