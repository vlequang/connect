package com.adobe.connect.synco.results
{
	import com.synco.script.Result;
	
	import flash.net.NetConnection;
	
	public class ConnectionResult extends Result
	{
		public var netConnection:NetConnection;
		public var loginInfo:Object;
		public var ticket:String;
		public function ConnectionResult(netConnection:NetConnection,loginInfo:Object=null,ticket:String=null)
		{
			super(netConnection!=null);
			this.netConnection = netConnection;
			this.loginInfo = loginInfo;
			this.ticket = ticket;
		}
	}
}