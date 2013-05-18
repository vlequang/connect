package com.adobe.connect.synco.pods
{
	import flash.display.Sprite;
	import flash.external.ExternalInterface;
	
	public class Pod extends Sprite
	{
		public function Pod()
		{
			super();
		}
		
		protected function get parameters():Object {
			return loaderInfo.parameters;
		}
		
		protected function get serverURL():String {
			return ExternalInterface.call("function(){return location.protocol+'//'+location.host;}");
		}
		
		
		protected function trace(...params):void {
			ExternalInterface.call("console.debug",">>"+params.join(" "));
		}
	}
}