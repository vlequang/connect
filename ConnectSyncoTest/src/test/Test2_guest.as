package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import flash.utils.getTimer;
	
	import test.common.Test;
	
	public class Test2_guest extends Test
	{
		public function Test2_guest()
		{
			var room:LiveRoom;
			var connect:Connect;
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					trace(sequence.step,"fetch connect");
					Connect.fetchConnect(domain,null,sequence.next);
				},
				function(result:ConnectResult):void {
					trace(sequence.step,"Connect Version:",result.version);
					connect = result.connect;
					trace(sequence.step,"check session");
					connect.session.fetchSession(sequence.next);
				},
				function(result:SessionResult):void {
					trace(sequence.step,"Session:",result.sessionID);
					trace(sequence.step,"Enter room");
					room = connect.getRoom(meetingroom);
					room.enter(sequence.next);
				},
				function(result:Result):void {
					room.enterAsGuest(guestname,sequence.next);
					trace(sequence.step,"Loging in as guest");
				},
				function(result:Result):void {
					validate(result.success);
					trace(sequence.step,"Connected to",room.netConnection.uri);
					trace(sequence.step,"logout");
					connect.session.logout(null,sequence.next);
				},
				function(result:Result):void {
					validate(result.success);
					trace(sequence.step,"done");
					validate();
				}
			);
		}
	}
}