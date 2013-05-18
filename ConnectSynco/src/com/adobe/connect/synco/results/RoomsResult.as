package com.adobe.connect.synco.results
{
	import com.synco.script.Result;
	
	public class RoomsResult extends Result
	{
		public var rooms:Array;
		public function RoomsResult(rooms:Array)
		{
			super(rooms!=null);
			this.rooms = rooms;
		}
	}
}