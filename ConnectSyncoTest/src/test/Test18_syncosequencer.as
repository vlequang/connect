package test
{
	import com.synco.interfaces.ISequence;
	import com.synco.script.Sequence;
	import com.synco.utils.SyncoUtil;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import test.common.Test;

	public class Test18_syncosequencer extends Test
	{
		public function Test18_syncosequencer()
		{
			var count:int = 0;
			var sequence:ISequence = new com.synco.script.Sequence();//Sequence.create("sequence");
			var func:Function;
			sequence.run(
				function():void {
					trace(sequence.stepProgress);
					SyncoUtil.callAsync(sequence.next);
				},
				function():void {
					trace(sequence.stepProgress);
					SyncoUtil.callAsync(sequence.next,["test"]);
				},
				function(msg:String):void {
					trace(sequence.stepProgress,msg);
					setTimeout(sequence.next,1000,'test2');
				},
				function(msg:String):void {
					trace(sequence.stepProgress,msg);
					setTimeout(sequence.next,2000,'first');
					setTimeout(sequence.next,1000,'second');
					setTimeout(sequence.next,300,'third');
				},
				function(first:String,second:String,third:String):void {
					trace(sequence.stepProgress,first,second,third);
					setTimeout(sequence.next,2000,'first');
					setTimeout(sequence.next,10,'second.1','second.2');
					setTimeout(sequence.next,300,'third');
				},
				function(...params):void {
					trace(sequence.stepProgress,params);
					sequence.next();
				},
				function():void {
					trace(sequence.stepProgress,"Test repeat ",count);
					if(count<5) {
						count++;
						sequence.repeat();
					}
					setTimeout(sequence.next,Math.random()*1000);
				},
				function():void {
					trace(sequence.stepProgress,"Test jump over the error via index");
					sequence.jump(2);
					SyncoUtil.callAsync(sequence.next);
				},
				function():void {
					throw new Error("ERROR!");
				},
				function():void {
					trace(sequence.stepProgress,"Test jump over the error via function");
					sequence.jump(func);
					SyncoUtil.callAsync(sequence.next);
				},
				function():void {
					throw new Error("ERROR!");
				},
				func = function():void {
					trace(sequence.stepProgress,"three attempts");
					var timer:Timer = new Timer(1000,3);
					timer.addEventListener(TimerEvent.TIMER,sequence.next);
					timer.start();
					count = 0;
				},
				function(e:TimerEvent=null):* {
					count++;
					trace(sequence.stepProgress,"attempt",count);
//					if(count<3) {
//						return Sequence.BLOCK;
//					}
//					else {
						sequence.next();
//					}
				},
				function():void {
					trace(sequence.stepProgress,"Done");
					validate();
				}
			);
		}
	}
}