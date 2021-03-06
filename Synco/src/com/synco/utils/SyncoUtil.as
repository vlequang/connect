package com.synco.utils
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	/**	▇ ▅ █ ▅ ▇ ▂ ▃ ▁ ▁ ▅ ▃ ▅ ▅ ▄ ▅ ▇ ▇ ▅ █ ▅ ▇ ▂ ▃ ▁ ▁ ▅ ▃ ▅ ▅ ▄ 
	 **		SyncoUtil
	 **	A Lot of utilities for using asynchronous calls better
	 **/
	public class SyncoUtil
	{
		static public var instance:SyncoUtil = new SyncoUtil();
		
		public var calls:Array = [];
		public var timer:Timer = new Timer(0,1);

		function SyncoUtil():void {
			timer.addEventListener(TimerEvent.TIMER_COMPLETE,onTimerComplete);
		}
		
		static protected function initialize():void {
			instance = new SyncoUtil();
		}
		
		//****************	ASYNCHRONOUS CALLS ******************
		static public function callAsync(call:Function,params:Array=null):void {
			instance.callAsync(call,params,false);
		}
		
		static public function callAsyncOnce(call:Function,params:Array=null):void {
			instance.callAsync(call,params,true);
		}

		static public function waitAndCall(time:int,call:Function,params:Array=null):void {
			var timeout:int = setTimeout(
				function():void {
					clearTimeout(timeout);
					callAsync(call,params);
				},time,params);
		}
		/////// private
		private function callAsync(call:Function,params:Array,once:Boolean):void {
			if(call==null) {
				throw new ArgumentError();
			}
			if(once) {
				for each(var pair:Array in calls) {
					if(pair[0]==call) {
						return;
					}
				}
			}
			calls.push([call,params]);
			timer.start();
		}
		
		private function onTimerComplete(e:TimerEvent):void {
			for each(var pair:Array in calls) {
				pair[0].apply(null,pair[1]?pair[1]:[]);
			}
			calls = [];
			timer.reset();
		}
	}
}