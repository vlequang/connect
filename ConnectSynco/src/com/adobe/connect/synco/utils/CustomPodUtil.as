package com.adobe.connect.synco.utils
{
	import com.adobe.connect.synco.results.ConnectionResult;
	import com.synco.utils.SyncoUtil;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.net.NetConnection;

	public class CustomPodUtil
	{
		static public function GrabNetConnection(currentSwf:DisplayObject,callback:Function):void
		{
			if(currentSwf.stage) {
				var netConnection:NetConnection = (currentSwf.parent.parent.root as Object).document.getChildAt(1)._session.fcsConnector.nc;
				SyncoUtil.callAsync(callback,[new ConnectionResult(netConnection)]);
			}
			else {
				currentSwf.addEventListener(Event.ADDED_TO_STAGE,
					function(e:Event):void {
						var netConnection:NetConnection = null;
						try {
							netConnection = (currentSwf.parent.parent.root as Object).document.getChildAt(1)._session.fcsConnector.nc;
						} catch(e:Error) {
							//	no netConnection
						}
						
						if(netConnection) {
							e.currentTarget.removeEventListener(e.type,arguments.callee);
							SyncoUtil.callAsync(callback,[new ConnectionResult(netConnection)]);
						}
					});
			}
		}
	}
}