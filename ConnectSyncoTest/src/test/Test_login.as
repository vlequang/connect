package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.adobe.connect.synco.results.UserResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import test.common.Test;
	
	public class Test_login extends Test
	{
		public function Test_login()
		{
			description = "Test login";
		}
		
		override protected function init():void {
			
			var sequence:Sequence = new Sequence();
			var connect:Connect;
			sequence.run(
				function():void {
					trace(sequence.step,"fetch connect");
					Connect.fetchConnect(domain,null,sequence.next);
				},
				function(result:ConnectResult):void {
					validate(result.success,result.version);
					trace(sequence.step,"Connect Version:",result.version);
					connect = result.connect;
					trace(sequence.step,"check session");
					connect.session.fetchSession(sequence.next);
				},
				function(result:SessionResult):void {
					validate(result.success,result.sessionID);
					trace(sequence.step,"Session:",result.sessionID);
					trace(sequence.step,"check user");
					connect.session.fetchUser(sequence.next);
				},
				function(result:UserResult):void {
					trace(sequence.step,"User:",JSON.stringify(result.user));
					trace(sequence.step,"login");
					connect.session.login(username,password,null,sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"check user");
					connect.session.fetchUser(sequence.next);
				},
				function(result:UserResult):void {
					validate(result.success,result.user);
					trace(sequence.step,JSON.stringify(result.user));
					trace(sequence.step,"logout");
					connect.session.logout(null,sequence.next);
				},
				function(result:Result):void{
					trace(sequence.step,"check user");
					connect.session.fetchUser(sequence.next);
				},
				function(result:UserResult):void {
					validate(!result.user);
					trace(sequence.step,"User:",JSON.stringify(result.user));
					trace(sequence.step,"done");
					validate();
				}
			);
		}
	}
}