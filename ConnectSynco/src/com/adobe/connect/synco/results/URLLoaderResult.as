package com.adobe.connect.synco.results
{
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	
	import flash.utils.ByteArray;
	
	public class URLLoaderResult extends DataResult
	{
		public var url:String;
		public function URLLoaderResult(url:String,data:Object=null)
		{
			super(data);
			this.url = url;
			success = url!=null;
		}
	}
}