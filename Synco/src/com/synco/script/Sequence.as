package com.synco.script
{
	import com.synco.interfaces.ISequence;

	/**	▇ ▅ █ ▅ ▇ ▂ ▃ ▁ ▁ ▅ ▃ ▅ ▅ ▄ ▅ ▇ ▇ ▅ █ ▅ ▇ ▂ ▃ ▁ ▁ ▅ ▃ ▅ ▅ ▄ 
	 **		SEQUENCE
	 **	allows sequencial calls of functions asynchronously
	 **	Sequence can be accessed between functions to go to next or previous steps
	 **/
	public class Sequence implements ISequence
	{
		private var parent:Sequence;
		private var calls:Vector.<SequenceNode>;
		public var step:uint, nextStep:uint, currentCalls:Vector.<Function>;
		public var callInProgress:Function;
		
		public function Sequence()
		{
			
		}
		
		public function get next():Function 
		{
			if(!calls) {
				return doNothing;
			}
			else if(nextStep>=calls.length) {
				return end;
			}
			else {
				var node:SequenceNode = calls[nextStep];
				return node ? node.entryNode() : doNothing;
			}
		}
		
		public function keepRunning(...params):void {
			callInProgress = calls[step].callback;
			for each(var node:SequenceNode in calls)
				node.clear();
			callInProgress.apply(null,params);
		}
		
		private function end(...params):void {
			if(parent) {
				parent.keepRunning.apply(null,params);
			}
		}
		
		private function doNothing(...params):void {
		}
		
		public function run(...script):void 
		{
			parent = null;
			assign.apply(this,script);
			begin();
		}
		
		private function begin(...params):void {
			calls[0].entryNode().apply(null,params);
		}
		
		public function assign(...script):void {
			calls = new Vector.<SequenceNode>(script.length,true);
			for(var i:int=0; i<script.length; i++) {
				if(script[i] is Function) {
					calls[i] = new SequenceNode(i,script[i],this);
				}
				else if(script[i] is Sequence) {
					var sequence:Sequence = script[i] as Sequence;
					sequence.parent = this;
					calls[i] = new SequenceNode(i,sequence.begin,this);
				}
			}
		}
		
		public function get stepProgress():String {
			return parent ? parent.stepProgress + "." + step : step +"";
		}
		
		public function repeat():void {
			nextStep = step;
//			calls[nextStep].clear();
		}
		
		public function jump(position:*):void {
			if(!isNaN(position)) {
				nextStep = step + position;
			}
			else {
				for each(var node:SequenceNode in calls) {
					if(node.callback==position) {
						nextStep = node.step;
						break;
					}
				}
			}
		}
		
		public function cancel():void {
			calls = null;
			step = nextStep = 0;
		}
	}
}


import com.synco.script.Sequence;

internal class SequenceNode 
{
	public var step:uint;
	public var callback:Function;
	private var parent:Sequence;
	private var entryPoints:Vector.<Function> = new Vector.<Function>();
	private var parameters:Vector.<Array> = new Vector.<Array>();
	private var entryCount:int;
	private var paramCount:uint;
	public var callInProgress:Function;
	
	public function SequenceNode(step:uint, callback:Function, parent:Sequence):void {
		this.step = step;
		this.parent = parent;
		this.paramCount = 0;
		this.callback = callback;
	}
	
	public function clear():void {
//		callInProgress = parent.callInProgress;
//		entryPoints = new Vector.<Function>();
//		parameters = new Vector.<Array>();
		for(var i:int=0;i<entryPoints.length;i++) {
			entryPoints[i] = null;
			parameters[i] = null;
		}
		paramCount = 0;
		entryCount = 0;
	}
	
	public function entryNode():Function {
		if(parent.callInProgress != callInProgress)
		{
//			clear();
		}
		
		var index:int = entryCount++;
		while(index>=entryPoints.length) {
			entryPoints.push(null);
			parameters.push(null);
		}

		var entryPoint:Function = entryPoints[index];
		var node:SequenceNode = this;
		if(entryPoint == null) {
			entryPoints[index] = entryPoint = 
				function(...params):void {
					if(!node.parameters[index])
						paramCount++;
					node.parameters[index] = params;
					if(paramCount == node.parameters.length) {
						parent.currentCalls = node.entryPoints.concat();
						parent.step = step;
						parent.nextStep = step+1;
						var paramsCombo:Array = node.parameters[0];
						for(var i:int=1;i<node.parameters.length;i++) {
							paramsCombo = paramsCombo.concat(node.parameters[i]);
						}
						parent.keepRunning.apply(null,paramsCombo);
					}
				};
		}
		return entryPoint;
	}	
}