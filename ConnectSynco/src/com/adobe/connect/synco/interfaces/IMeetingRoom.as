package com.adobe.connect.synco.interfaces
{
	public interface IMeetingRoom
	{
		function fetchMeetingObject(id:String,type:String,params:Array,callback:Function,sync:Boolean=false):void;
		function fetchMeetingStream(id:String,mode:String,callback:Function):void;
		function serverCall(type:String,action:String,params:Array,callback:Function=null):void;
	}
}