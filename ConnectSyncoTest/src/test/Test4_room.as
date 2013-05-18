package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.adobe.connect.synco.results.UserResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import flash.events.MouseEvent;
	
	import test.common.Test;

	public class Test4_room extends Test
	{
		public function Test4_room()
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
					trace(sequence.step,"Login");
					connect.session.login(username,password,null,sequence.next);
				},
				function(result:Result):void{
					trace(sequence.step,"check user");
					connect.session.fetchUser(sequence.next);
				},
				function(result:UserResult):void {
					trace(sequence.step,"User:",JSON.stringify(result.user));
					connect.session.fetchSession(sequence.next);
				},
				function(result:SessionResult):void {
					trace(sequence.step,"Session:",result.sessionID);
					trace(sequence.step,"Enter room");
					room = connect.getRoom(meetingroom);
					room.enter(sequence.next);
				},
				function(result:Result):void {
					validate(room.netConnection);
					trace(sequence.step,"Connected to",room.netConnection.uri);
					trace("<Click to continue>");
					stage.addEventListener(MouseEvent.CLICK,sequence.next);
				},
				function(e:MouseEvent):void {
					e.currentTarget.removeEventListener(e.type,sequence.currentCalls[0]);
					trace(sequence.step,"Leave Room");
					room.leave();
					trace(sequence.step,"Logout");
					connect.session.logout(null,sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"Enter Room");
					room.enter(sequence.next);
				},
				function(result:Result):void {
					room.enterAsGuest(guestname,sequence.next);
					trace(sequence.step,"Loging in as guest");
				},
				function(result:Result):void {
					validate(room.netConnection);
					trace(sequence.step,"Connected to",room.netConnection.uri);
					trace(sequence.step,"logout");
					connect.session.logout(null,sequence.next);
				},
				function(result:Result):void {
					validate();
				}
			);
		}
	}
}