package test.common
{
	import com.adobe.connect.synco.live.LiveRoom;
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.utils.getQualifiedClassName;

	public class Test extends Sprite
	{
		static public var STANDARD_WIDTH:int = 300;
		
		protected var username:String = "vlequang@adobe.com";
		protected var password:String = "Breeze8";
		
		protected var domain:String = "my.adobeconnect.com";
		protected var meetingroom:String = "vincent";
		
		public var description:String = "No description.";
		
		private var _log:TextField;
		private var logEntries:Array = [];
		private var completelyValid:Boolean;
		private var loginScreen:Sprite = new Sprite();
		
		public function Test()
		{
			addChild(loginScreen);
			var tf:TextField, bottomY:int=2;
			tf = new TextField();
			tf.name = "domain";
			tf.text = domain;
			tf.type = TextFieldType.INPUT;
			tf.width = stage?stage.stageWidth:STANDARD_WIDTH;
			tf.height = 16;
			tf.y = bottomY+2;
			tf.border = true;
			bottomY = tf.y+tf.height;
			loginScreen.addChild(tf);
			tf = new TextField();
			tf.name = "meetingroom";
			tf.text = meetingroom;
			tf.type = TextFieldType.INPUT;
			tf.width = stage?stage.stageWidth:STANDARD_WIDTH;
			tf.height = 16;
			tf.y = bottomY+2;
			tf.border = true;
			bottomY = tf.y+tf.height;
			loginScreen.addChild(tf);
			tf = new TextField();
			tf.name = "username";
			tf.text = username;
			tf.type = TextFieldType.INPUT;
			tf.width = stage?stage.stageWidth:STANDARD_WIDTH;
			tf.height = 16;
			tf.y = bottomY+2;
			tf.border = true;
			bottomY = tf.y+tf.height;
			loginScreen.addChild(tf);
			tf = new TextField();
			tf.name = "password";
			tf.text = password;
			tf.displayAsPassword = true;
			tf.type = TextFieldType.INPUT;
			tf.width = stage?stage.stageWidth:STANDARD_WIDTH;
			tf.height = 16;
			tf.y = bottomY+2;
			tf.border = true;
			bottomY = tf.y+tf.height;
			loginScreen.addChild(tf);
			tf = new TextField();
			tf.name = "start";
			tf.htmlText = "<a href='event:login'> START </a>";
			tf.type = TextFieldType.DYNAMIC;
			tf.autoSize = TextFieldAutoSize.CENTER;
			tf.y = bottomY+2;
			tf.border = true;
			bottomY = tf.y+tf.height;
			loginScreen.addChild(tf);
			tf.addEventListener(TextEvent.LINK,
				function(e:TextEvent):void {
					start();
				});
		}
		
		public function get className():String {
			return getQualifiedClassName(this);
		}
		
		public function setParameters(
			domain:String,
			meetingroom:String,
			username:String,
			password:String):void {
			(loginScreen.getChildByName("domain") as TextField).text = this.domain = domain;
			(loginScreen.getChildByName("meetingroom") as TextField).text = this.meetingroom = meetingroom;
			(loginScreen.getChildByName("username") as TextField).text = this.username = username;
			(loginScreen.getChildByName("password") as TextField).text = this.password = password;
		}
		
		public function start():void {
			if(loginScreen.parent==this)
				removeChild(loginScreen);
			domain = (loginScreen.getChildByName("domain") as TextField).text;
			meetingroom = (loginScreen.getChildByName("meetingroom") as TextField).text;
			username = (loginScreen.getChildByName("username") as TextField).text;
			password = (loginScreen.getChildByName("password") as TextField).text;
			trace("Test:", getQualifiedClassName(this));
			completelyValid = true;
			init();
		}
		
		protected function get guestname():String {
			return username;
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