package com.adobe.connect.synco.results
{
	import com.synco.script.Result;
	
	public class UserResult extends Result
	{
		public var user:Object;
		public function UserResult(user:Object)
		{
			super(user!=null);
			this.user = user;
		}
	}
}