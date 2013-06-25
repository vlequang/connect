package
{
	import com.adobe.connect.widget.Connector;
	import com.adobe.connect.widget.chat.IChatReceiver;
	
	import flash.display.Sprite;
	
	public class ConnectorPlay extends Sprite
		implements IChatReceiver
	{
		private var connector:Connector;
		public function ConnectorPlay()
		{
			connector = new Connector();
			connector.chat.addReceiver(this,true);
			connector.chat.sendMessage("hello");
			connector.connect("https://meet97493778.adobeconnect.com","play","Vincent");
		}
		
		public function receiveMessage(message:Object):void {
			trace(JSON.stringify(message));
		}
	}
}