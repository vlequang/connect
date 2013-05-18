package com.adobe.connect.synco.javascript
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.results.JavascriptInterfaceResult;
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.utils.SyncoUtil;
	
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;
	import flash.system.Security;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	public class JavascriptInterface extends EventDispatcher
	{
		private var callbacks:Vector.<Function> = new Vector.<Function>(1);
		private var recycledSlots:Vector.<int> =new Vector.<int>();
		
//		[Embed(source="connectsynco.js",mimeType="")]
		private static const SCRIPT:String = 
			<![CDATA[
				window.messages = [];
				window.addEventListener('message', 
					function (e) {
			            if(!e.data.flash) {
    						  returnCommands(e.data);
			            }
						if(window.messages.length) {
							var obj = {messages:window.messages};
							window.messages = [];
							e.source.postMessage(obj,e.origin);
						}
					},false);
			]]>;
		
		public function JavascriptInterface()
		{
		}
		
		public function initialize(callback:Function):void {
			
			addEventListener(JavascriptEvent.JSEVENT,
				function(e:JavascriptEvent):void {
					if(e.action=='trust') {
						e.currentTarget.removeEventListener(e.type,arguments.callee);
						callback(new Result(true));
					}
				});
			
			Security.allowDomain("*");
			ExternalInterface.addCallback("returnCommands", returnCommands);
			ExternalInterface.call("function(movieName){var isIE = navigator.appName.indexOf('Microsoft') != -1; var flashObj = isIE ? window[movieName] : document[movieName]; window.returnCommands = function(obj) {flashObj.returnCommands(obj);};}",ExternalInterface.objectID);
			ExternalInterface.call("function(){"+SCRIPT+"}");
			sendToJavascript({action:'salut'},callback);
		}
		
		private function fromJavaScript(obj:Object):void {
			obj.timeout = setTimeout(returnCommands,0,obj);
		}
		
		private function returnCommands(obj:Object):void {
			clearTimeout(obj.timeout);
			delete obj.timeout;
			if(obj.callbackResult) {
				var func:Function = callbacks[obj.callbackResult];
				callbacks[obj.callbackResult] = null;
				recycledSlots.push(obj.callbackResult);
				func(new DataResult(obj.data));
			}
			else {
				dispatchEvent(new JavascriptEvent(obj.action,obj));
				if(obj.action!='hi')
					trace("from JS:",JSON.stringify(obj));
			}
		}
		
		public function sendToJavascript(obj:Object,callback:Function=null):void {
			if(callback!=null) {
				if(!recycledSlots.length) {
					recycledSlots.push(callbacks.length);
					callbacks.push(null);
				}
				obj.callbackID = recycledSlots.pop();
				callbacks[obj.callbackID] = callback;
			}
			ExternalInterface.call("function(){var obj="+JSON.stringify(obj)+"; window.messages.push(obj);}");
		}
	}
}