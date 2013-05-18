package com.adobe.connect.synco.login
{
	import com.adobe.connect.synco.results.ImageResult;
	import com.adobe.connect.synco.results.URLLoaderResult;
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	
	public class ImageLoader extends Loader
	{
		private var httpLoader:HTTPLoader;
		private var callback:Function;
		public function ImageLoader(url:String,params:Object,method:String,callback:Function):void
		{
			this.callback = callback;
			httpLoader = new HTTPLoader(url,params,method,httpLoaderCallback);
			addEventListener(Event.COMPLETE,onComplete);
		}
		
		public function cancel():void {
			httpLoader.cancel();
			close();
		}

		private function httpLoaderCallback(result:URLLoaderResult):void {
			if(result.success) {
				loadBytes(result.bytes);
			}
			else {
				callback(result);
			}
		}
		
		private function onComplete(e:Event):void {
			var imageResult:ImageResult = new ImageResult((content as Bitmap).bitmapData);
			callback(imageResult);			
		}

		static public function get(url:String,params:Object,callback:Function):ImageLoader {
			var loader:ImageLoader = new ImageLoader(url,params,URLRequestMethod.GET,callback);
			loader.httpLoader.selfLoad();
			return loader;
		}
		
		static public function post(url:String,params:Object,callback:Function):ImageLoader {
			var loader:ImageLoader = new ImageLoader(url,params,URLRequestMethod.POST,callback);
			loader.httpLoader.selfLoad();
			return loader;
		}
	}
}