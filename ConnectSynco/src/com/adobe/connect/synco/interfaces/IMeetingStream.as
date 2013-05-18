package com.adobe.connect.synco.interfaces
{
	import flash.net.NetStream;

	public interface IMeetingStream
	{
		function get id():String;
		function get stream():NetStream;
		function close():void;
	}
}