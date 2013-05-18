package com.synco.utils
{
	import flash.utils.Dictionary;

	public class ObjectPool
	{
		private var ClassObj:Class;
		private var objPool:Vector.<Object> = new Vector.<Object>();
		private var objPoolAvailable:int = 0;
		
		function ObjectPool(ClassObj:Class) {
			this.ClassObj = ClassObj;
		}
		
		public function create():* {
			var item:*;
			if(objPoolAvailable>0) {
				item = objPool[--objPoolAvailable];
			}
			else {
				item = new ClassObj();
				objPool.push(item);
			}
			return item;
		}
		
		public function recycle():void {
			objPoolAvailable = objPool.length;
		}
	}
}