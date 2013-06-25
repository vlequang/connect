package com.adobe.connect.synco.live
{
	import com.adobe.connect.synco.core.PodType;
	import com.adobe.connect.synco.interfaces.IMeetingObject;
	import com.adobe.connect.synco.interfaces.IMeetingRoom;
	import com.adobe.connect.synco.login.ConnectionFetch;
	import com.adobe.connect.synco.login.Session;
	import com.adobe.connect.synco.results.ConnectionResult;
	import com.adobe.connect.synco.results.DataResultResponder;
	import com.adobe.connect.synco.results.MeetingObjectResult;
	import com.adobe.connect.synco.results.MeetingStreamResult;
	import com.adobe.connect.synco.results.SessionResult;
	import com.synco.result.ArrayResult;
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.script.Sequence;
	import com.synco.utils.SyncoUtil;
	
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.SyncEvent;
	import flash.events.TimerEvent;
	import flash.net.NetConnection;
	import flash.net.Responder;
	import flash.utils.Timer;
	
	public class LiveRoom implements IMeetingRoom
	{
		private var room:String;
		private var session:Session;
		private var liveObjects:Object = {};
		private var liveStreams:Object = {};
		
		private var loginInfo:Object;
		public var ticket:String;
		public var netConnection:NetConnection;
		public var passcode:String = null;
		
		public function LiveRoom(room:String,session:Session)
		{
			this.room = room;
			this.session = session;
		}
		
		public function enter(callback:Function=null):void {
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					session.fetchSession(sequence.next);
				},
				function(result:SessionResult):void {
					var options:Object = {};
					if(passcode) {
						options["meeting-passcode"] = passcode;
					}
					ConnectionFetch.getConnection(session.url+"/"+room,null,options,sequence.next);
				},
				function(result:ConnectionResult):void {
					onConnectionFetched(result.netConnection,result.loginInfo,result.ticket);
					if(callback!=null)
						callback(result);
				}
			);
		}

		public function enterLogin(username:String,password:String,callback:Function=null):void {
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					session.login(username,password,null,sequence.next);
				},
				function(result:Result):void {
					enter(callback);
				});
		}

		public function enterAsGuest(guestName:String,callback:Function=null):void {
			var sequence:Sequence = new Sequence();
			sequence.run(
				function():void {
					session.fetchSession(sequence.next);
				},
				function(result:SessionResult):void {
					var options:Object = {guestName:guestName};
					if(passcode) {
						options["meeting-passcode"] = passcode;
					}
					ConnectionFetch.getConnection(session.url+"/"+room,result.sessionID,options,sequence.next);
				},
				function(result:ConnectionResult):void {
					onConnectionFetched(result.netConnection,result.loginInfo,result.ticket);
					if(callback!=null)
						callback(result);
				}
			);
		}
		
		private function onConnectionFetched(netConnection:NetConnection,loginInfo:Object,ticket:String):void {
			this.loginInfo = loginInfo;
			this.netConnection = netConnection;
			this.ticket = ticket;
			
			if(this.netConnection)
				this.netConnection.addEventListener(NetStatusEvent.NET_STATUS,onNetStatus);
		}
		
		private function onNetStatus(e:NetStatusEvent):void {
			trace(e.info.code);
		}
		
		public function get userName():String {
			return loginInfo.userName;
		}
		
		public function get userID():String {
			return loginInfo.userID;
		}
		
		public function get connected():Boolean {
			return netConnection!=null;
		}
		
		public function fetchMeetingObject(id:String,type:String,params:Array,callback:Function,sync:Boolean=false):void {
			var tag:String = PodType.getSharedObjectName(id,type,params);
			
			var syncFunction:Function = null;
			if(sync) {
				syncFunction = createSyncFunction(
					function(e:TimerEvent):void {
						fetchMeetingObject(id,type,params,callback);
					});
			}
			
			var liveObj:LiveObject = liveObjects[tag];
			if(liveObj) {
				if(liveObj.data) {
					SyncoUtil.callAsync(callback,[new MeetingObjectResult(liveObj)]);
				}
				else {
					liveObj.addEventListener(Event.INIT,
						function(e:Event):void {
							e.currentTarget.removeEventListener(e.type,arguments.callee);
							callback(new MeetingObjectResult(liveObj));
						});
				}
			}
			else {
				liveObjects[tag] = liveObj = LiveObject.create(id,type,params,this,
					function(result:Result):void {
						if(syncFunction!=null)
							liveObj.addEventListener(SyncEvent.SYNC,syncFunction);
						callback(new MeetingObjectResult(result.success?liveObj:null));
					}
				);
			}
		}
		
		public function fetchMeetingStream(id:String,mode:String,callback:Function):void {
			var tag:String = id+"_"+mode;
			var liveStream:LiveStream = liveStreams[tag];
			if(liveStream) {
				SyncoUtil.callAsync(callback,[new MeetingStreamResult(liveStream)]);
			}
			else {
				liveStreams[tag] = liveStream = LiveStream.create(id,mode,this,
					function(result:Result):void {
						callback(new MeetingStreamResult(result.success?liveStream:null));
					});
			}
		}
		
		public function fetchContent(id:String,callback:Function):void {
			var sequence:Sequence = new Sequence();
			var contentDB:IMeetingObject,content:IMeetingObject;
			sequence.run(
				function():void {
					fetchMeetingObject(null,PodType.CONTENTDB,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					contentDB = result.meetingObject;
					fetchMeetingObject(id,PodType.CONTENT,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					content = result.meetingObject;
					callback(new DataResult(contentDB.data[content.data.ctID]));
				}
			);
		}
		
		private function createSyncFunction(func:Function):Function {
			var timer:Timer = new Timer(0,1);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE,func);
			return function(e:SyncEvent):void {
				timer.start();
			};
		}
		
		public function fetchActivePods(type:String,callback:Function,sync:Boolean=false):void {
			var sequence:Sequence = new Sequence();
			var saveStateObj:IMeetingObject,layoutObj:IMeetingObject;
			var activeLayout:Object;
			
			var syncFunction:Function = null;
			if(sync) {
				syncFunction = createSyncFunction(
					function(e:TimerEvent):void {
						fetchActivePods(type,callback);
					});
			}
			
			sequence.run(
				function():void {
					fetchMeetingObject(null,PodType.LAYOUT_SAVEDSTATE,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					saveStateObj = result.meetingObject;
					if(syncFunction!=null)
						saveStateObj.addEventListener(SyncEvent.SYNC,syncFunction);
					fetchMeetingObject(null,PodType.LAYOUT_LAYOUT,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					layoutObj = result.meetingObject;
					if(syncFunction!=null)
						layoutObj.addEventListener(SyncEvent.SYNC,syncFunction);
					fetchMeetingObject(null,PodType.PODS,null,sequence.next);
				},
				function(result:MeetingObjectResult):void {
					var pods:IMeetingObject = result.meetingObject;
					var ids:Array = [];
					activeLayout = layoutObj.data[saveStateObj.data.roomLayoutID];
					for(var id:String in activeLayout.modules) {
						if(!type || pods.data[id].type==type) {
							ids.push(id);
						}
					}
					ids.reverse();
					callback(new ArrayResult(ids));
				}
			);
		}
		
		public function fetchActiveSharePods(shareType:String,callback:Function):void {
			var id:String;
			var idsToTry:Array = [];
			var sequence:Sequence = new Sequence();
			var pods:Array = [];
			sequence.run(
				function():void {
					fetchActivePods("FtContent",sequence.next);
				},
				function(result:ArrayResult):void {
					idsToTry = result.array;
					sequence.next();
				},
				function():void {
					if(!idsToTry.length) {
						callback(new ArrayResult(pods));
						return;
					}
					id = idsToTry.pop();
					fetchContent(id,sequence.next);
				},
				function(result:DataResult):void {
					var info:Object = result.data;
					if(info && info.shareType==shareType) {
						pods.push(id);
					}
					sequence.jump(-1);
					SyncoUtil.callAsync(sequence.next);
				}
			);
		}
		
		public function closeNetStream(id:String):void {
			var tag:String = id;
			var liveStream:LiveStream = liveStreams[tag];
			if(liveStream) {
				liveStream.close();
				delete liveStreams[tag];
			}
		}
		
		public function closeMeetingObject(id:String,type:String,params:Array):void {
			var tag:String = PodType.getSharedObjectName(id,type,params);
			var liveObject:LiveObject = liveObjects[tag];
			if(liveObject) {
				liveObject.close();
				delete liveObjects[tag];
			}
		}
		
		private function serverToClientCall(id:String, methodName:String, args:Array):void {
			trace(id);
		}
		
		public function serverCall(type:String,action:String,params:Array,callback:Function=null):void {
			var responder:Responder;
			if(callback!=null) {
				responder = new DataResultResponder(callback);
			}
			netConnection.call.apply(null,[type,responder,action].concat(params));
		}
		
		public function leave():void {
			if(netConnection) {
				netConnection.close();
			}
			netConnection = null;
			loginInfo = null;
		}
	}
}