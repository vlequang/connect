package com.adobe.connect.widget.core
{
	import com.adobe.connect.widget.Connector;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	[Event(name="connect", type="flash.events.Event")]
	public class Module extends EventDispatcher
	{
		protected var connector:Connector;
		private var _connected:Boolean;
		
		public function Module(connector:Connector)
		{
			this.connector = connector;
			if(connector.connected) {
				connect();
			}
			else {
				connector.addEventListener(Event.CONNECT,onConnect);
			}
		}
		
		private function onConnect(e:Event):void {
			if(e) {
				e.currentTarget.removeEventListener(e.type,arguments.callee);
			}
			connect();
		}
		
		protected function get connected():Boolean {
			return _connected;
		}
		
		protected function set connected(value:Boolean):void {
			if(_connected != value) {
				_connected = value;
				if(value) {
					dispatchEvent(new Event(Event.CONNECT));
				}
			}
		}
		
		protected function waitForConnection(args:Array):Boolean {
			if(connected) {
				return false;
			}
			addEventListener(Event.CONNECT,
				function(e:Event):void {
					e.currentTarget.removeEventListener(e.type,arguments.callee);
					args.callee.apply(null,args);
				});
			return true;
		}
		
		protected function connect():void {
		}	
	}
}