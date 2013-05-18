package com.adobe.connect.synco.results
{
	import com.adobe.connect.synco.interfaces.IMeetingStream;
	import com.synco.script.Result;
	
	public class MeetingStreamResult extends Result
	{
		public var stream:IMeetingStream;
		public function MeetingStreamResult(stream:IMeetingStream)
		{
			super(stream!=null);
			this.stream = stream;
		}
	}
}