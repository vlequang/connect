package test.common
{
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	dynamic public class ProxyClient extends Proxy
	{
		private var obj:Object = null;
		public function ProxyClient(obj:Object=null)
		{
			this.obj = obj || {};
		}
		
		flash_proxy override function getProperty(name:*):* {
			if(obj.hasOwnProperty(name)) {
				return obj[name];
			}
			else {
				return function(...params):void {
					trace("Getting property: ",name,JSON.stringify(params));;
				}
			}
		}
	}
}