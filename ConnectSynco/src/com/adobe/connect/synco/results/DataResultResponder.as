package com.adobe.connect.synco.results
{
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	
	import flash.net.Responder;
	
	public class DataResultResponder extends Responder
	{
		private var callback:Function;
		public function DataResultResponder(callback:Function, status:Function=null)
		{
			super(onResponderResult, status);
			this.callback = callback;
		}
		
		private function onResponderResult(data:Object):void {
			callback(new DataResult(data));
		}
	}
}