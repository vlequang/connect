package com.adobe.connect.synco.results
{
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.synco.script.Result;
	
	public class MeetingObjectResult extends Result
	{
		public var meetingObject:IMeetingObject;
		public function MeetingObjectResult(meetingObject:IMeetingObject)
		{
			super(meetingObject!=null);
			this.meetingObject = meetingObject;
		}
	}
}