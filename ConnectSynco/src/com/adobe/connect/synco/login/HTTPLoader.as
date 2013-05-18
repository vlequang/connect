package com.adobe.connect.synco.login
{
	import com.adobe.connect.synco.results.URLLoaderResult;
	import com.adobe.connect.synco.utils.UploadPostHelper;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.Timer;

	public class HTTPLoader extends URLLoader
	{
		static private const TIMEOUT:int = 7000;
		static private const RETRIES:int = 3;
		static private const PAUSE:int = 5000;
		
		static public var refresh:Boolean = true;
		
		private var refreshCount:int = 0;
		private var request:URLRequest = new URLRequest();
		private var timer:Timer = new Timer(TIMEOUT,1);
		private var pauseTimer:Timer = new Timer(PAUSE,1);
		private var callback:Function;
		private var retry:int;
		
		public function get url():String {
			return request.url;
		}
		
		function HTTPLoader(url:String,params:Object,method:String,callback:Function):void {
			dataFormat = URLLoaderDataFormat.BINARY;
			request.url = url;
			request.method = method;
			for(var id:String in params) {
				if(!request.data) {
					request.data =new URLVariables();
				}
				request.data[id] = params[id];
			}
			if(refresh && method==URLRequestMethod.GET) {
				request.data.refresh = refreshCount++;
			}
			
			this.callback = callback;
			timer.addEventListener(TimerEvent.TIMER_COMPLETE,onFail);
			pauseTimer.addEventListener(TimerEvent.TIMER_COMPLETE,onPauseComplete);
			addEventListener(IOErrorEvent.IO_ERROR,onFail);
			addEventListener(SecurityErrorEvent.SECURITY_ERROR,onCompleteFail);
			addEventListener(Event.COMPLETE,onComplete);
			addEventListener(Event.OPEN,onLoading);
		}
		
		static public function get(url:String,params:Object,callback:Function):HTTPLoader {
			var loader:HTTPLoader = new HTTPLoader(url,params,URLRequestMethod.GET,callback);
			loader.selfLoad();
			return loader;
		}
		
		static public function post(url:String,params:Object,callback:Function):HTTPLoader {
			var loader:HTTPLoader = new HTTPLoader(url,params,URLRequestMethod.POST,callback);
			loader.selfLoad();
			return loader;
		}
		
		static public function upload(url:String,params:Object,filename:String,bytes:ByteArray,callback:Function):HTTPLoader {
			var loader:HTTPLoader = new HTTPLoader(url,params,URLRequestMethod.POST,callback);
			loader.request.url = loader.request.url+"?"+loader.request.data;
			loader.request.contentType = 'multipart/form-data; boundary=' + UploadPostHelper.getBoundary();
			loader.request.data = UploadPostHelper.getPostData(filename, bytes);
			loader.request.requestHeaders.push( new URLRequestHeader( 'Cache-Control', 'no-cache' ) );
			loader.selfLoad();
			return loader;
		}
		
		private function onFail(e:Event):void {
			retry = retry?retry:0;
			if(retry<RETRIES) {
				retry = retry+1;
				pauseTimer.reset();
				pauseTimer.start();
			}
			else {
				onCompleteFail(null);
			}
		}
		
		private function onPauseComplete(e:TimerEvent):void {
			load(request);
		}
		
		private function onCompleteFail(e:Event):void {
			cleanUp();
			callback(new URLLoaderResult(null));
		}
		
		private function onComplete(e:Event):void {
			cleanUp();
			callback(new URLLoaderResult(request.url,data));
		}
		
		private function cleanUp():void {
			removeEventListener(IOErrorEvent.IO_ERROR,onFail);
			removeEventListener(SecurityErrorEvent.SECURITY_ERROR,onFail);
			removeEventListener(Event.COMPLETE,onComplete);
			timer.removeEventListener(TimerEvent.TIMER_COMPLETE,onFail);
			pauseTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,onPauseComplete);
			timer.stop();
			pauseTimer.stop();
		}
		
		private function onLoading(e:Event):void {
			timer.reset();
			timer.start();
		}
		
		public function cancel():void {
			close();
			cleanUp();
		}
		
		public function selfLoad():void {
			retry = 0;
			load(request);
		}
	}
}