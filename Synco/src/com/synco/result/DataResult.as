package com.synco.result
{
	import com.synco.script.Result;
	
	import flash.utils.ByteArray;
	
	/**	▇ ▅ █ ▅ ▇ ▂ ▃ ▁ ▁ ▅ ▃ ▅ ▅ ▄ ▅ ▇ ▇ ▅ █ ▅ ▇ ▂ ▃ ▁ ▁ ▅ ▃ ▅ ▅ ▄ 
	 **		DATARESULT
	 **	Used by ISynco to retrieve data results
	 **/
	public class DataResult extends Result
	{
		public var data:Object;
		public function DataResult(data:Object)
		{
			super(data!=null);
			this.data = data;
		}
		
		public function get text():String {
			try {
				return String(data);
			}
			catch (error:TypeError) {
			}
			return null;
		}
		
		public function get bytes():ByteArray {
			try {
				return ByteArray(data);
			}
			catch (error:TypeError) {
			}
			return null;
		}
	}
}