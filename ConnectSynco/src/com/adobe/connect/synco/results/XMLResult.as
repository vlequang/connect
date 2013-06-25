package com.adobe.connect.synco.results
{
	import com.synco.script.Result;
	
	public class XMLResult extends Result
	{
		public var xml:XML;
		public function XMLResult(xml:XML)
		{
			super(xml!=null);
			this.xml = xml;
		}
	}
}