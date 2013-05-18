package com.adobe.connect.synco.results
{
	import com.adobe.connect.synco.core.Connect;
	import com.synco.script.Result;
	
	public class ConnectResult extends Result
	{
		public var connect:Connect;
		public var version:String;
		public function ConnectResult(connect:Connect,version:String=null)
		{
			super(connect!=null);
			this.connect = connect;
			this.version = version;
		}
	}
}