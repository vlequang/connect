package com.synco.script
{
	/**	▇ ▅ █ ▅ ▇ ▂ ▃ ▁ ▁ ▅ ▃ ▅ ▅ ▄ ▅ ▇ ▇ ▅ █ ▅ ▇ ▂ ▃ ▁ ▁ ▅ ▃ ▅ ▅ ▄ 
	 **		RESULT
	 **	is a base class for standard object returned in callbacks
	 **	Can be derived to have callbacks returned more structured results.
	 **/
	dynamic public class Result
	{
		/** Succesful result. */
		public var success:Boolean;

		public function Result(success:Boolean,params:Object=null)
		{
			this.success = success;
			for(var i:String in params) {
				this[i] = params[i];
			}
		}
	}
}