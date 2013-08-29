package
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.adobe.connect.synco.results.UserResult;
	import com.adobe.connect.synco.utils.URLUtils;
	import com.synco.result.ArrayResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	import com.synco.utils.SyncoUtil;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
	import flash.net.SharedObject;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	

	
	public class ConnectFakeAttendee extends Sprite
	{
		private var loginScreen:Sprite = new Sprite();
		protected var username:String = "vlequang@adobe.com";
		protected var password:String = "Breeze2013";
		
		protected var domain:String = "<enter domain>";
		protected var meetingroom:String = "testroom";
		
		private var entrymessage:String = "";
		private var time:String = new Date().toLocaleString();;
		
		private var attendees:IMeetingObject;
		private var activated:Boolean;
		
		private var timer:Timer = new Timer(1000);
		private var started:Boolean, validTimer:Boolean;
		
		
		private var room:LiveRoom;
		private var chatObj:IMeetingObject;
		
		public function ConnectFakeAttendee()
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
			tf.name = "time";
			tf.text = new Date().toLocaleString();
			tf.type = TextFieldType.INPUT;
			tf.width = stage.stageWidth;
			tf.height = 16;
			tf.y = bottomY+2;
			tf.border = true;
			tf.addEventListener(FocusEvent.FOCUS_OUT,onFocusOut);
			bottomY = tf.y+tf.height;
			loginScreen.addChild(tf);
			
			tf = new TextField();
			tf.name = "entrymessage";
			tf.text = "Need to do something. BRB";
			tf.type = TextFieldType.INPUT;
			tf.width = stage.stageWidth;
			tf.height = 16;
			tf.y = bottomY+2;
			tf.border = true;
			bottomY = tf.y+tf.height;
			loginScreen.addChild(tf);
			tf.addEventListener(Event.CHANGE,onChange);	
			
			tf = new TextField();
			tf.multiline = false;
			tf.addEventListener(TextEvent.LINK,onLink);
			tf.name = "start";
			tf.y = bottomY+2;
			tf.width = stage.stageWidth;
			tf.height = 16;
			tf.htmlText = "<a href='event:start'>[ START ]</a>";
			loginScreen.addChild(tf);
			bottomY = tf.y+tf.height;
			
			tf = new TextField();
			tf.multiline = true;
			tf.name = "chat";
			tf.y = bottomY+2;
			tf.width = stage.stageWidth;
			tf.height = stage.stageHeight-2 - tf.y;
			loginScreen.addChild(tf);
			bottomY = tf.y+tf.height;

			
			timer.addEventListener(TimerEvent.TIMER,onTimer);
			timer.start();
			
		}
		
		private function onTimer(e:TimerEvent):void {
			if(activated) {
				if(new Date().time < Date.parse((loginScreen.getChildByName("time") as TextField).text)) {
					validTimer = true;
				}
				if(!started && validTimer && new Date().time > Date.parse((loginScreen.getChildByName("time") as TextField).text)) {
					started = true;
					enter();
				}
			}
			updateStartButton();
		}
		
		private function enter():void {
			connect(domain,meetingroom,username,password);
		}
		
		private function onFocusOut(e:FocusEvent):void {
			validTimer = started = activated = false;
			var tf:TextField = e.currentTarget as TextField;
			tf.text = new Date(Date.parse(tf.text)).toLocaleString();
			updateStartButton();
		}
		
		private function onLink(e:TextEvent):void {
			var tf:TextField = e.currentTarget as TextField;
			activated = !activated;
			updateStartButton();
		}
		
		private function updateStartButton():void {
			var tf:TextField = (loginScreen.getChildByName("start") as TextField);
			tf.htmlText = activated ? 
				"<a href='event:start'>[ STOP ]</a> " + formatTime(timeLeft()) 
				: "<a href='event:start'>[ START ]</a> " + (timeLeft()>0?"":" - <font color='#cc0000'>Meeting Time must be in the future</font>");
		}
		
		private function formatTime(time:Number):String {
			if(time<0) return "";
			else {
				var diff:Number = time/1000;
				if(diff < 60) {
					return int(diff) + " sec.";
				}
				diff /= 60;	//	minutes
				if(diff < 60) {
					return int(diff) + " min.";
				}
				diff /= 60;	//	hours
				if(diff < 24) {
					return int(diff) + " hours.";
				}
				diff /= 24;
				return int(diff) + " days.";
			}
		}
		
		private function timeLeft():Number {
			var now:Number = new Date().time;
			var trigger:Number = Date.parse((loginScreen.getChildByName("time") as TextField).text);
			return trigger-now;
		}
		
		private function onChange(e:Event):void {
			domain = (loginScreen.getChildByName("domain") as TextField).text;
			meetingroom = (loginScreen.getChildByName("meetingroom") as TextField).text;
			username = (loginScreen.getChildByName("username") as TextField).text;
			password = (loginScreen.getChildByName("password") as TextField).text;
			entrymessage = (loginScreen.getChildByName("entrymessage") as TextField).text;
			
			var so:SharedObject = SharedObject.getLocal("syncotester");
			if(so.data.domain != domain)
				so.setProperty("domain",domain);
			if(so.data.meetingroom != meetingroom)
				so.setProperty("meetingroom",meetingroom);
			if(so.data.username != username)
				so.setProperty("username",username);
			if(so.data.password != password)
				so.setProperty("password",password);
			if(so.data.entrymessage != entrymessage)
				so.setProperty("entrymessage",entrymessage);
		}
		
		private function get chatbox():TextField {
			return (loginScreen.getChildByName("chat") as TextField);
		}
		
		private function connect(domain:String,meetingroom:String,username:String,password:String):void {
			var connect:Connect;
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					Connect.fetchConnect(domain,null,sequence.next);
				},
				function(result:ConnectResult):void {
					chatbox.appendText("Connect Version: "+result.version+"\n");
					connect = result.connect;
					connect.session.fetchSession(sequence.next);
				},
				function(result:SessionResult):void {
					chatbox.appendText("Session: "+result.sessionID+"\n");
					connect.session.login(username,password,null,sequence.next);
				},
				function(result:Result):void{
					connect.session.fetchUser(sequence.next);
				},
				function(result:UserResult):void {
					chatbox.appendText("User: "+JSON.stringify(result.user)+"\n");
					connect.session.fetchSession(sequence.next);
				},
				function(result:SessionResult):void {
					room = connect.getRoom(meetingroom);
					room.enter(sequence.next);
				},
				function(result:Result):void {
					chatbox.appendText("Room "+meetingroom+" entered"+"\n");
					room.fetchActivePods("FtChat",sequence.next);
				},
				function(result:ArrayResult):void {
					var chatPodID:String = result.array[0];
					room.fetchMeetingObject(chatPodID,PodType.CHATMESSAGES,null,sequence.next);
				},
				function(result:Result):void {
					chatObj = result.meetingObject;
					chatObj.addCallback("message",receiveMessage);
					
					setTimeout(sendFakeMessage,8000+Math.random()*4000);
					
					room.fetchMeetingObject(null,PodType.ATTENDEES,null,sequence.next,true);
				},
				function(result:MeetingObjectResult):void {
					attendees = result.meetingObject;
					var selfAttendee:Object = attendees.data[room.userID];
					for each(var attendee:Object in attendees.data) {
						if(attendee.id != room.userID) {
							if(attendee.pID == selfAttendee.pID) {
								SyncoUtil.callAsync(sequence.next);
								break;
							}
						}
					}
				},
				function():void {
					chatbox.appendText("Bye Bye!"+"\n");
					room.leave();
					connect.session.logout(null,sequence.next);
				}
			);
		}
		
		private function sendFakeMessage():void {
			if((loginScreen.getChildByName("entrymessage") as TextField).text.length)
				chatObj.serverCall("sendMessage",[0,(loginScreen.getChildByName("entrymessage") as TextField).text,-1,'Black',-1]);
		}
		
		private function receiveMessage(msg:Object):void {
			chatbox.appendText(msg.fromName + ": " + msg.text+"\n");
		}
	}
}