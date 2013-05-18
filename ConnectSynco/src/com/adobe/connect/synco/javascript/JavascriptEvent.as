package com.adobe.connect.synco.javascript
{
	import flash.events.Event;
	
	public class JavascriptEvent extends Event
	{
		static public const JSEVENT:String = "jsevent";
		public var obj:Object;
		public var action:String;
		public function JavascriptEvent(action:String,obj:Object)
		{
			super(JSEVENT);
			this.action = action;
			this.obj = obj;
		}
	}
}