package test.common
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getQualifiedClassName;

	public class Test extends Sprite
	{
		protected var username:String = "vlequang@adobe.com";
		protected var password:String = "Breeze8";
		
		protected var domain:String = "my.adobeconnect.com";
		protected var meetingroom:String = "vincent";
		protected var guestname:String = "guestdude";
		
		private var _log:TextField;
		private var logEntries:Array = [];
		private var completelyValid:Boolean;
		
		public function Test()
		{
			trace("Test:", getQualifiedClassName(this));
			completelyValid = true;
			init();
		}
		
		protected function init():void {
		}
		
		private function get logger():TextField {
			if(!_log) {
				_log = new TextField();
				_log.multiline = true;
				_log.defaultTextFormat = new TextFormat("courier");
				_log.width = stage.stageWidth;
				_log.height = stage.stageHeight;
				addChild(_log);
			}
			return _log;
		}
		
		private function set htmlText(value:String):void {
			if(logger) {
				logger.htmlText = value;
				logger.setSelection(logger.length,logger.length);
			}
		}
		
		protected function trace2(...params):void {
			log.apply(this,params);
		}

		protected function trace(...params):void {
			log.apply(this,params);
		}

		protected function log(...params):void {
//			trace.apply(null,params);
			logEntries.push(params.join(" ").split("<").join("&lt;").split(">").join("&gt;"));
			htmlText = logEntries.join("\n")+"\n";
		}
		
		protected function validate(...truthStatements):void {
			var valid:Boolean = truthStatements.length ? true : completelyValid;
			for each(var bool:Boolean in truthStatements) {
				valid &&= bool;
			}
			completelyValid &&= valid;
			if(logEntries.length) {
				logEntries[logEntries.length-1] += " <b>"+ (valid?"<font color='#00aa00'>√</font></b>":"<b><font color='#FF0000'>X</font>") + "</b>";
				htmlText = logEntries.join("\n");
			}
			else {
				trace("validation:",valid?"√":"X");
			}
		}
	}
}