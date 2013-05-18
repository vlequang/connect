package com.adobe.connect.synco.utils
{
	import flash.net.URLVariables;

	public class URLUtils
	{
		//	copied from mx.utils.URLUtil
		public static function getProtocol(url:String):String
		{
			var slash:int = url.indexOf("/");
			var indx:int = url.indexOf(":/");
			var protocol:String = "";
			if (indx > -1 && indx < slash)
			{
				protocol = url.substring(0, indx);
			}
			else
			{
				indx = url.indexOf("::");
				if (indx > -1 && indx < slash)
					protocol = url.substring(0, indx);
			}
			
			return protocol;
		}
		
		public static function getUrl(request:String):String 
		{
			var protocolParts:Array = request.split("://");
			var url:String = protocolParts.length > 1?protocolParts[1]:protocolParts[0];
			var requestParts:Array = url.split("?");
			return requestParts[0];
		}
		
		public static function getDomain(request:String):String
		{
			return getUrl(request).split("/")[0];
		}
		
		
		public static function getParameters(request:String):URLVariables 
		{
			var protocolParts:Array = request.split("://");
			var vars:URLVariables = new URLVariables();
			if (protocolParts.length > 1) 
			{
				var requestParts:Array = protocolParts[1].split("?");
				if (requestParts.length > 1) 
				{
					vars.decode(requestParts[1]);
				}
			}
			return vars;
		}
		
//		public static function get
	}
}