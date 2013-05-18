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
		static protected var instance:SyncoUtil = new SyncoUtil();
		
		private var calls:Array = [];
		private var timer:Timer = new Timer(0,1);

		function SyncoUtil():void {
			timer.addEventListener(TimerEvent.TIMER_COMPLETE,onTimerComplete);
		}
		
		static protected function initialize():void {
			instance = new SyncoUtil();
		}
		
		//****************	ASYNCHRONOUS CALLS ******************
		static public function callAsync(call:Function,params:Array=null):void {
			instance.callAsync(call,params);
		}

		static public function waitAndCall(time:int,call:Function,params:Array=null):void {
			var timeout:int = setTimeout(
				function():void {
					clearTimeout(timeout);
					callAsync(call,params);
				},time,params);
		}
		/////// private
		private function callAsync(call:Function,params:Array):void {
			if(call==null)
				throw new ArgumentError();
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