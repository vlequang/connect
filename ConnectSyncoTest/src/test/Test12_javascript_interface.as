package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.javascript.JavascriptInterface;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.JavascriptInterfaceResult;
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	
	import flash.external.ExternalInterface;
	
	import test.common.Test;
	
	public class Test12_javascript_interface extends Test
	{
		private var javascript:JavascriptInterface;
		
		public function Test12_javascript_interface()
		{
			var connect:Connect;
			var sequence:Sequence = new Sequence();
			var javascript:JavascriptInterface = new JavascriptInterface();
			sequence.run(
				function():void {
					javascript.initialize(sequence.next);
				},
				function(result:Result):void {
					trace(sequence.step,"fetch connect");
					Connect.fetchConnect(domain,null,sequence.next);
				},
				function(result:ConnectResult):void {
					trace(sequence.step,"Connect Version:",result.version);
					connect = result.connect;
				}
			);
		}
		
		override protected function log(...params):void {
			ExternalInterface.call("console.debug",">>"+params.join(" "));
		}
	}
}