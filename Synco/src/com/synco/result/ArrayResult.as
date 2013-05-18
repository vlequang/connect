package com.synco.result
{
	public class ArrayResult extends DataResult
	{
		public function ArrayResult(array:Array)
		{
			super(array);
		}
		
		public function get array():Array {
			return data as Array;
		}
	}
}