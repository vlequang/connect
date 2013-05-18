package com.synco.interfaces
{
	public interface ISequence
	{
		function get next():Function;
		function run(...script):void;
		function get stepProgress():String;
		function repeat():void;
		function jump(position:*):void;
		function cancel():void;
		function assign(...params):void;
	}
}