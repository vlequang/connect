package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.login.HTTPLoader;
	import com.adobe.connect.synco.login.Session;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.ConnectionResult;
	import com.adobe.connect.synco.results.RoomsResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.adobe.connect.synco.results.URLLoaderResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import test.common.Test;
	
	public class Test_aicc extends Test
	{
		public function Test_aicc()
		{
			password = "breeze9";
			domain = "http://mobile.adobe.acrobat.com";
			meetingroom = "vcbyminh";
			
			var room:LiveRoom;
			var connect:Connect;
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					log(sequence.step,"fetch connect");
					Connect.fetchConnect(domain,null,sequence.next);
				},
				function(result:ConnectResult):void {
					log(sequence.step,"Connect Version:",result.version);
					connect = result.connect;
					log(sequence.step,"check session");
					connect.session.fetchSession(sequence.next);
				},
				function(result:SessionResult):void {
					log(sequence.step,"Session:",result.sessionID);
					log(sequence.step,"Login");
					connect.session.login(username,password,null,sequence.next);
				},
				function(result:Result):void {
					log(sequence.step,"Enter room");
					room = connect.getRoom(meetingroom);
					room.passcode = "minh";
					room.enter(sequence.next);
				},
				function(result:ConnectionResult):void {
					log(sequence.step,"Connected to",room.netConnection.uri);
					log(sequence.step,"Ticket is: "+room.ticket);
					return;
					var urlloader:URLLoader = new URLLoader();
					var request:URLRequest = new URLRequest(connect.session.url+"/servlet/verify?sco-id=33521");
					request.method = URLRequestMethod.POST;
					request.requestHeaders.push(new URLRequestHeader("cookie","BREEZESESSION="+connect.session.sessionID));
					request.data = new URLVariables();
					
					request.data.command="getParam";
					request.data.aicc_data="";
					request.data.session_id=room.ticket;
					request.data.version=3.5;
					
					urlloader.addEventListener(Event.COMPLETE,sequence.next);
					
					log("Calling :",request.url);
					log("Parameters:",request.data);
					urlloader.load(request);
				},
				function(e:Event):void {
					var urlloader:URLLoader = e.currentTarget as URLLoader;
					log(urlloader.data);
					log("<Click to continue>");
					stage.addEventListener(MouseEvent.CLICK,sequence.next);
				},
				function(e:MouseEvent):void {
					log(sequence.step,"Leave Room");
					room.leave();
					log(sequence.step,"Logout");
					connect.session.logout(null,sequence.next);
				}
			);
		}
	}
}