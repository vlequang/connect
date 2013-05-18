package com.adobe.connect.synco.interfaces
{
	import flash.events.IEventDispatcher;

	public interface IMeetingObject extends IEventDispatcher
	{
		function get id():String;
		function get type():String;
		function get data():Object;
		function set sync(value:Function):void;
		function setProperty(property:String,value:Object):void;
		function setDirty(property:String):void;
		function serverCall(action:String,params:Array,callback:Function=null):void;
		function addCallback(action:String,func:Function):void;
		function close():void;
	}
}