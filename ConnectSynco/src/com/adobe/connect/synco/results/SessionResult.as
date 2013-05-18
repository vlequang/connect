package com.adobe.connect.synco.results
{
	import com.synco.script.Result;
	
	public class SessionResult extends Result
	{
		public var sessionID:String;
		public function SessionResult(sessionID:String)
		{
			super(sessionID!=null);
			this.sessionID = sessionID;
		}
	}
}