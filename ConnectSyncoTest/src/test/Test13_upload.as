package test
{
	import com.adobe.connect.synco.core.Connect;
	import com.adobe.connect.synco.live.LiveRoom;
	import com.adobe.connect.synco.results.ConnectResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.adobe.connect.synco.results.URLLoaderResult;
	import com.adobe.connect.synco.results.UserResult;
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	import com.synco.utils.SyncoUtil;
	
	import flash.display.BitmapData;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import by.blooddy.crypto.image.PNGEncoder;
	
	import test.common.Test;

	public class Test13_upload extends Test
	{
		public function Test13_upload()
		{
			var connect:Connect;
			var scoID:String;
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
				function(result:Result):void {
					connect.session.fetchUser(sequence.next);
				},
				function(result:UserResult):void {
					trace(sequence.step,JSON.stringify(result.user));
					trace(sequence.step,"Check file content");
					connect.contentManager.getScoID("ham",sequence.next);
				},
				function(result:DataResult):void {
					trace(sequence.step,"Sco:",JSON.stringify(result));
					if(result.success) {
						sequence.jump(2);
						sequence.next(result);
					}
					else {
						sequence.next();
					}
				},
				function(result:Result=null):void {
					connect.contentManager.createSco("922758257","ham","ham",sequence.next);
				},
				function(result:DataResult=null):void {
					trace(sequence.step,"ScoID:",result?result.text:"");
					var image:BitmapData = new BitmapData(250,160);
					image.noise(123);
					var tf:TextField = new TextField();
					tf.filters = [new GlowFilter(0xFFFFFF,1,10,10,10)];
					tf.text = new Date().toString();
					image.draw(tf);
					scoID = result.text;
					var bytes:ByteArray = PNGEncoder.encode(image);
					connect.contentManager.upload(scoID,"ham.png",bytes,sequence.next);
				},
				function(result:Result=null):void {
					trace(sequence.step,"Uploaded");
					sequence.next();
				},
				function(result:Result=null):void {
					trace(sequence.step,"Wait ...");
					SyncoUtil.waitAndCall(100,sequence.next,[result]);
				},
				function(result:DataResult):void {
					if(result)
						trace(sequence.step,"Check status. ",result.text);
					if(!result || result.text!='ok') {
						sequence.jump(-1);
					}
					connect.contentManager.getScoStatus(scoID,sequence.next);
				},
				function(result:DataResult):void {
					trace("Done");
					validate();
				}
			);
		}
	}
}