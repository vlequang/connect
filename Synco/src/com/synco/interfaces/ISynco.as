package com.synco.interfaces
{
	public interface ISynco
	{
		function listMembers(callback:Function):void;
		function fetch(query:String,callback:Function):void;
	}
}