package com.synco.result
{
	import com.synco.script.Result;
	
	/**	▇ ▅ █ ▅ ▇ ▂ ▃ ▁ ▁ ▅ ▃ ▅ ▅ ▄ ▅ ▇ ▇ ▅ █ ▅ ▇ ▂ ▃ ▁ ▁ ▅ ▃ ▅ ▅ ▄ 
	 **		LISTRESULT
	 **	used by ISynco.list to retrieve a list of properties associated with a synco
	 **/
	public class ListMemberResult extends DataResult
	{
		public function ListMemberResult(members:Object)
		{
			super(members!=null);
		}
		
		public function get members():Object {
			return data;
		}
	}
}