package com.adobe.connect.synco.results
{
	import com.adobe.connect.synco.javascript.JavascriptInterface;
	import com.synco.script.Result;
	
	public class JavascriptInterfaceResult extends Result
	{
		public var javascript:JavascriptInterface;
		public function JavascriptInterfaceResult(javascript:JavascriptInterface)
		{
			super(javascript!=null);
			this.javascript = javascript;
		}
	}
}