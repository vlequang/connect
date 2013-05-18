package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.adobe.connect.synco.results.UserResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import flash.external.ExternalInterface;
	
	import test.common.Test;
	
	public class Test10_javascript extends Test
	{
		public function Test10_javascript()
		{
			
			ExternalInterface.addCallback("returnCommands", returnCommands);
			ExternalInterface.call("function(){parent.flashObj=document.getElementById('"+ExternalInterface.objectID+"');  parent.returnCommands = function(params) {parent.flashObj.returnCommands(params);};}");
		}
		
		private function returnCommands(...params:Array):void {
			trace(params);
		}

		override protected function init():void {
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
					trace(sequence.step,"check user");
					connect.session.fetchUser(sequence.next);
				},
				function(result:UserResult):void {
					trace(sequence.step,"User:",JSON.stringify(result.user));
					trace(sequence.step,"login");
					if(!result.user) {
						var seq:Sequence = new Sequence();
						seq.run(
							function():void {
								connect.session.logout(null,seq.next);
							},
							function():void {
								ExternalInterface.call("function(){parent.location='"+connect.session.url+"/system/login?next='+parent.location;}");
							});
					}
					else {
						trace(sequence.step,"check user");
						connect.session.fetchUser(sequence.next);
					}
				},
				function(result:UserResult):void {
					trace(sequence.step,JSON.stringify(result.user));
					trace(sequence.step,"logout");
					connect.session.logout(null,sequence.next);
				},
				function(result:Result):void{
					trace(sequence.step,"check user");
					connect.session.fetchUser(sequence.next);
				},
				function(result:UserResult):void {
					trace(sequence.step,"User:",JSON.stringify(result.user));
					trace(sequence.step,"done");
				}
			);
		}
		
		override protected function log(...params):void {
			ExternalInterface.call("console.debug",">>"+params.join(" "));
			//node.appendChild(document.createTextNode(txt));
			ExternalInterface.call("(function(txt){if(!parent.logger)document.body.insertBefore(parent.logger=document.createElement('pre'),document.body.firstChild);})");
			ExternalInterface.call("(function(txt){parent.logger.appendChild(document.createTextNode(txt));})",params.join(" ")+"\n");
		}
	}
}