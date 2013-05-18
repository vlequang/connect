package com.adobe.connect.synco.live
{
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.results.DataResultResponder;
	import com.synco.script.Result;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SyncEvent;
	import flash.net.SharedObject;
	
	public class LiveObject extends EventDispatcher implements IMeetingObject
	{
		private var _type:String;
		private var _id:String;
		private var _params:Array;
		private var _room:LiveRoom;
		public var sharedObject:SharedObject;
		private var syncFunction:Function;

		public function LiveObject()
		{
		}
		
		static public function create(id:String,type:String,params:Array,room:LiveRoom,callback:Function):LiveObject {
			var liveObject:LiveObject = new LiveObject();
			liveObject._id = id;
			liveObject._type= type;
			liveObject._params = params;
			liveObject._room = room;
			liveObject.connect(callback);
			return liveObject;
		}
		
		private function connect(callback:Function):void {
			var typePreference:Array = PodType.preference[type];
			var name:String = PodType.getSharedObjectName(_id,_type,_params);
			var customParams:Boolean = typePreference.length==1;
			var persistence:Object = customParams?_params[0]:typePreference[1];
			var secure:Object = customParams?_params[1]:typePreference[2];
			var so:SharedObject = SharedObject.getRemote(name,_room.netConnection.uri,persistence,secure);
			so.addEventListener(SyncEvent.SYNC,onSync);
			so.client = {};
			
			if(callback!=null) {
				so.addEventListener(SyncEvent.SYNC,
					function(e:SyncEvent):void {
						e.currentTarget.removeEventListener(e.type,arguments.callee);
						sharedObject = so;
						callback(new Result(true));
						dispatchEvent(new Event(Event.INIT));
					});
			}
			so.connect(_room.netConnection);
		}
		
		private function onSync(e:SyncEvent):void {
			if(syncFunction!=null)
				syncFunction(e);
			if(e)
				dispatchEvent(e);
		}
		
		public function get data():Object {
			return sharedObject ? sharedObject.data : null;
		}
		
		public function get type():String
		{
			return _type;
		}
		
		public function get id():String
		{
			return _id;
		}
		
		public function close():void {
			if(sharedObject) {
				sharedObject.removeEventListener(SyncEvent.SYNC,onSync);
				sharedObject.close();
				sharedObject = null;
			}
		}
		
		public function set sync(value:Function):void {
			syncFunction = value;
			if(data && syncFunction!=null) {	//	initialized
				onSync(null);
			}
		}
		
		public function serverCall(action:String, params:Array, callback:Function=null):void
		{
			_room.netConnection.call("clientToServerCall", callback!=null?new DataResultResponder(callback):null, id, action, params);
		}
		
		public function addCallback(action:String, func:Function):void 
		{
			sharedObject.client[action] = func;
		}
		
		public function setProperty(property:String,value:Object):void {
			if(sharedObject) {
				sharedObject.setProperty(property,value);
			}
		}
		
		public function setDirty(property:String):void {
			if(sharedObject) {
				sharedObject.setDirty(property);
			}
		}
	}
}