package test
{
	import com.adobe.connect.api.ConnectAudio;
	import com.adobe.connect.api.ConnectChat;
	import com.adobe.connect.api.ConnectCore;
	import com.adobe.connect.api.ConnectPoll;
	import com.adobe.connect.api.events.ConnectEvent;
	import com.adobe.connect.api.users.ConnectUser;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import test.common.Test;
	
	public class Test23_connectcore extends Test
	{
		private var videoContainer:Sprite = new Sprite();
		
		public function Test23_connectcore()
		{
			addChild(videoContainer);
			ConnectCore.instance.addEventListener(ConnectEvent.REQUEST_LOGIN,promptLogin);
			ConnectCore.instance.addEventListener(ConnectEvent.ENTER_ROOM,enterRoom);
			ConnectCore.instance.addEventListener(ConnectEvent.UPDATE_ATTENDEES,updateAttendees);
			ConnectCore.instance.connect(domain,meetingroom);
			ConnectAudio.audio = ConnectAudio.UNIFIED_VOICE;
			stage.addEventListener(MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent):void {
//					var cam:Camera = Camera.getCamera();
//					cam.setMode(320,240,12);
//					ConnectCore.instance.selfUser.attachCamera(cam);
					
//					ConnectAudio.audio = ConnectAudio.audio==ConnectAudio.UNIFIED_VOICE?ConnectAudio.OFF:ConnectAudio.UNIFIED_VOICE;
					
					ConnectChat.instance.addEventListener(ConnectEvent.CHAT,trace);
				});
			
		}
		
		private function promptLogin(e:ConnectEvent):void {
			trace("Prompt login:",username);
			//ConnectCore.instance.login(username,password);
			ConnectCore.instance.loginAsGuest(username);
		}
		
		private function enterRoom(e:ConnectEvent):void {
			trace("Enter room");
			ConnectPoll.instance.addEventListener(ConnectEvent.VOTECHANGED,
				function(e:ConnectEvent):void {
					trace(JSON.stringify(e.data,null,'\t'));
//					trace(JSON.stringify(ConnectPoll.instance.votes,null,'\t'));
				});
		}
		
		private function updateAttendees(e:ConnectEvent):void {
			for(var id:String in ConnectCore.instance.users) {
				if(!videoContainer.getChildByName("video"+id)) {
					var user:ConnectUser = ConnectCore.instance.users[id];
					user.addEventListener(Event.CLOSE,
						function(e:Event):void {
							if(user.video.parent)
								videoContainer.removeChild(user.video);
						});
					videoContainer.addChild(user.video);
				}
			}
		}
	}
}