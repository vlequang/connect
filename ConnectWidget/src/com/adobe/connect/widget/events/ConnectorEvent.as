package com.adobe.connect.widget.events
{
	import flash.events.Event;
	
	public class ConnectorEvent extends Event
	{
		public function ConnectorEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}