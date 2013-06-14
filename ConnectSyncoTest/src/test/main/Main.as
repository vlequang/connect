package test.main
{
	import com.adobe.connect.synco.utils.URLUtils;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.external.ExternalInterface;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import test.Test_QandA;
	import test.Test_attendees;
	import test.Test_chat;
	import test.Test_clear_chat_and_QnA;
	import test.Test_guest;
	import test.Test_imageshare;
	import test.Test_layout;
	import test.Test_listroom;
	import test.Test_login;
	import test.Test_pdfshare;
	import test.Test_pods;
	import test.Test_polls;
	import test.Test_presentershare;
	import test.Test_recording;
	import test.Test_room;
	import test.Test_sharedobject;
	import test.Test_syncosequencer;
	import test.Test_unifiedvoice;
	import test.Test_upload;
	import test.Test_video;
	import test.Test_viewscreenshare;
	import test.Test_webcambroadcasting;
	import test.Test_webcamrecording;
	import test.Test_whiteboard;
	import test.common.Test;

	public class Main extends Sprite
	{
		static public var TESTS:Array ;
		
		protected var username:String = "vlequang@adobe.com";
		protected var password:String = "Breeze2013";
		
		protected var domain:String = "<enter domain>";
		protected var meetingroom:String = "testroom";
		
		private var loginScreen:Sprite = new Sprite();
		private var back:TextField = new TextField();
		private var currentTest:Test;
		
		public function Main()
		{
			var so:SharedObject = SharedObject.getLocal("syncotester");
			if(so.data.username)
				username = so.data.username;
			if(so.data.password)
				password = so.data.password;
			if(so.data.domain) {
				domain = so.data.domain;
			}
			else {
				domain = URLUtils.getDomain(loaderInfo.url);
			}
			if(so.data.meetingroom) {
				meetingroom = so.data.meetingroom;
			}
			
			
			
			opaqueBackground = 0xEEEEEE;
			Test.STANDARD_WIDTH = stage.stageWidth;
			
			TESTS = [
				new Test_login,
				new Test_guest,
				new Test_recording,
				new Test_webcambroadcasting,
				new Test_webcamrecording,
				new Test_upload,
				new Test_video,
				new Test_whiteboard,
				new Test_layout,
				new Test_sharedobject,
				new Test_viewscreenshare,
				new Test_syncosequencer,
				new Test_imageshare,
				new Test_pdfshare,
				new Test_presentershare,
				new Test_unifiedvoice,
				new Test_polls,
				new Test_listroom,
				new Test_room,
				new Test_pods,
				new Test_chat,
				new Test_QandA,
				new Test_clear_chat_and_QnA,
				new Test_attendees,
			];
			
			TESTS.sortOn("className");
			
			back.autoSize = TextFieldAutoSize.LEFT;
			back.htmlText = "<a href='event:back'>[BACK]</a>";
			back.addEventListener(TextEvent.LINK,
				function(e:TextEvent):void {
					if(e.text=="back") {
						removeChild(back);
						removeChild(currentTest);
						currentTest = null;
						addChild(loginScreen);
						resetMe();
					}
				});
			
			addChild(loginScreen);
			var tf:TextField, bottomY:int=2;
			tf = new TextField();
			tf.name = "domain";
			tf.text = domain;
			tf.type = TextFieldType.INPUT;
			tf.width = stage.stageWidth;
			tf.height = 16;
			tf.y = bottomY+2;
			tf.border = true;
			bottomY = tf.y+tf.height;
			loginScreen.addChild(tf);
			tf.addEventListener(Event.CHANGE,onChange);
			tf = new TextField();
			tf.name = "meetingroom";
			tf.text = meetingroom;
			tf.type = TextFieldType.INPUT;
			tf.width = stage.stageWidth;
			tf.height = 16;
			tf.y = bottomY+2;
			tf.border = true;
			bottomY = tf.y+tf.height;
			loginScreen.addChild(tf);
			tf.addEventListener(Event.CHANGE,onChange);
			tf = new TextField();
			tf.name = "username";
			tf.text = username;
			tf.type = TextFieldType.INPUT;
			tf.width = stage.stageWidth;
			tf.height = 16;
			tf.y = bottomY+2;
			tf.border = true;
			bottomY = tf.y+tf.height;
			loginScreen.addChild(tf);
			tf.addEventListener(Event.CHANGE,onChange);
			tf = new TextField();
			tf.name = "password";
			tf.text = password;
			tf.displayAsPassword = true;
			tf.type = TextFieldType.INPUT;
			tf.width = stage.stageWidth;
			tf.height = 16;
			tf.y = bottomY+2;
			tf.border = true;
			bottomY = tf.y+tf.height;
			loginScreen.addChild(tf);
			tf.addEventListener(Event.CHANGE,onChange);
			tf = new TextField();
			tf.multiline = true;
			tf.name = "list";
			tf.y = bottomY+2;
			tf.width = stage.stageWidth;
			tf.height = stage.stageHeight-2 - tf.y;
			loginScreen.addChild(tf);
			var testList:Array = [];
			var count:int = 1;
			for each(var unitTest:Test in TESTS) {
				var className:String = unitTest.className;
				var name:String = className.split(":").pop();
				var description:String = unitTest.description;
				testList.push(
					count++ + " - <a href='event:"+className+"'>"+name+ " - " + description+"</a>"
				);
			}
			tf.htmlText = testList.join("<br>");
			tf.addEventListener(TextEvent.LINK,
				function(e:TextEvent):void {
					for each(var unitTest:Test in TESTS) {
						var className:String = unitTest.className;
						if(className==e.text) {
							currentTest = unitTest;
							removeChild(loginScreen);
							addChild(back);
							addChild(currentTest);
							currentTest.y = back.height+2;
							onChange(null);
							currentTest.setParameters(domain,meetingroom,username,password);
							currentTest.start();
							break;
						}
					}
				});
		}
		
		private function resetMe():void {
			var url:String = stage.loaderInfo.url;
			var request:URLRequest = new URLRequest(url);
			navigateToURL(request,"_level0");
		}		
		private function onChange(e:Event):void {
			domain = (loginScreen.getChildByName("domain") as TextField).text;
			meetingroom = (loginScreen.getChildByName("meetingroom") as TextField).text;
			username = (loginScreen.getChildByName("username") as TextField).text;
			password = (loginScreen.getChildByName("password") as TextField).text;
			var so:SharedObject = SharedObject.getLocal("syncotester");
			if(so.data.domain != domain)
				so.setProperty("domain",domain);
			if(so.data.meetingroom != meetingroom)
				so.setProperty("meetingroom",meetingroom);
			if(so.data.username != username)
				so.setProperty("username",username);
			if(so.data.password != password)
				so.setProperty("password",password);
		}
	}
}