package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.geom.Rectangle;
	import flash.media.StageWebView;
	
	public class StageWebViewer extends Sprite
	{
		private var webview:StageWebView = new StageWebView();
		
		public function StageWebViewer()
		{
			super();
			
			// support autoOrients
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			webview.viewPort = new Rectangle(0,0,stage.stageWidth,stage.stageHeight);
			webview.stage = stage;
			
			var SESSION:String = "ar1breezpih25uadnhsieii7";
			var mp4Link:String = "https://connectpro381253581.adobeconnect.com/connect_video/default/data/resources/Gladiator_258_1_39308.mp4?session="+SESSION;
			var contentLink:String = "https://connectpro381253581.adobeconnect.com/connect_video/?session="+SESSION;
			webview.loadURL(mp4Link);
		}
	}
}