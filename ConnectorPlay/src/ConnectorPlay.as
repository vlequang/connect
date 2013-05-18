package
{
	import com.adobe.connect.widget.Connector;
	import com.adobe.connect.widget.chat.IChatReceiver;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.setTimeout;
	
	public class ConnectorPlay extends Sprite
		implements IChatReceiver
	{
		private var connector:Connector;
		public function ConnectorPlay()
		{
			connector = new Connector();
			connector.connect("http://my.adobeconnect.com","vincent","Vincent");
			connector.addEventListener(Event.CONNECT,onConnect);
		}
		
		private function onConnect(e:Event):void {
			connector.chat.addReceiver(this,false);
		}
		
		public function receiveMessage(message:Object):void {
			trace(JSON.stringify(message));
		}
	}
}