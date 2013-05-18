package com.adobe.connect.synco.events
{
	import flash.events.Event;
	
	public class SessionEvent extends Event
	{
		public static const LOGIN:String = "login";
		public static const LOGOUT:String = "logout";
		public function SessionEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}