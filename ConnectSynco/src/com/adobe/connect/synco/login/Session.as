package com.adobe.connect.synco.login
{
	import com.adobe.connect.synco.results.SessionResult;
	import com.adobe.connect.synco.results.URLLoaderResult;
	import com.adobe.connect.synco.results.UserResult;
	import com.adobe.connect.synco.utils.URLUtils;
	import com.synco.result.DataResult;
	import com.synco.script.Result;
	import com.synco.utils.SyncoUtil;
	
	public class Session
	{
		private var protocol:String;
		private var domain:String;
		private var commonInfo:XMLList;
		
		public function Session() {
		}
		
		public function set url(value:String):void {
			if(url != value) {
				protocol = URLUtils.getProtocol(value);
				domain = URLUtils.getDomain(value);
				commonInfo = null;
			}
		}
		
		public function get url():String {
			return (protocol?protocol+"://":"") + domain;
		}
		
		public function get connected():Boolean {
			return sessionID!=null;
		}
		
		public function get sessionID():String {
			return commonInfo?commonInfo.cookie.toString():null;
		}
		
		public function get accountID():String {
			return commonInfo?commonInfo.account.attribute('account-id').toString():null;
		}
		
		private function processCallback(callback:Function,success:Boolean):void {
			callback(new Result(true));
		}
		
		private function getCommonInfo(session:String,callback:Function):void {
			processRequest({action:"common-info",session:session},
				function(result:URLLoaderResult):void {
					if(result.success) {
						try {
							var xml:XML = new XML(result.data);
							if(xml.status.@code=='ok') {
								commonInfo = xml.common;								
								protocol = URLUtils.getProtocol(result.url);
								processCallback(callback,true);
							}
							else
								processCallback(callback,false);
						}
						catch(error:Error) {
							trace(error);
							processCallback(callback,false);
						}
					}
					else {
						processCallback(callback,false);
					}
				});
		}
		
		private function processRequest(params:Object,callback:Function):void {
			var protocols:Array = protocol?[protocol]:["http","https"];
			var loaders:Array = [];
			var count:int = 0;
			
			if(!params.session)
				delete params.session;
			var onComplete:Function = function(result:URLLoaderResult):void {
				count++;
				if(result.success) {
					for each(var loader:HTTPLoader in loaders) {
						if(loader.url!=result.url) {
							loader.cancel();
						}
					}
					callback(result);
				}
				else if(count==loaders.length) {
					callback(new URLLoaderResult(null));
				}
			};
			
			for each(var protocol:String in protocols) {
				loaders.push(HTTPLoader.get(protocol+"://"+domain+"/api/xml",params,onComplete));
			}
		}
		
		public function login(username:String,password:String,session:String=null,callback:Function=null):void {
			if(!accountID) {
				getCommonInfo(session,
					function(result:Object):void {
						if(result.success)
							login(username,password,null,callback);
						else
							callback(result);
					}
				);
				return;
			}			
			
			var params:Object = {
				action:"login",
				login:username,
				password:password
			};
			if(session || sessionID)
				params.session = session || sessionID;
			if(accountID)
				params['account-id'] = accountID;
			
			processRequest(params,
				function(result:Object):void {
					try {
						var xml:XML = new XML(result.data);
						var success:Boolean = xml.status.@code=="ok";
						
						processCallback(callback,success);
					}
					catch(error:Error) {
						processCallback(callback,false);
					}
				});
		}
		
		public function logout(session:String=null,callback:Function=null):void {
			if(!session)
				session = sessionID;
			commonInfo = null;
			processRequest({action:"logout",session:session},
				function(result:Object):void {
					processCallback(callback,true);
				});
		}
		
		public function fetchUser(callback:Function):void {
			var user:Object = commonInfo && commonInfo.user.length() ?
				{
					name:commonInfo.user.name.toString(),
					login:commonInfo.user.login.toString()
				}:null;
			
			if(user) {
				SyncoUtil.callAsync(callback,[new UserResult(user)]);
			}
			else {
				getCommonInfo(null,
					function(result:Result):void {
						var user:Object = commonInfo && commonInfo.user.length() ?
						{
							name:commonInfo.user.name.toString(),
							login:commonInfo.user.login.toString()
						}:null;
						callback(new UserResult(user));
					});
			}
		}
		
		public function fetchSession(callback:Function):void {
			if(sessionID) {
				SyncoUtil.callAsync(callback,[new SessionResult(sessionID)]);
			}
			else {
				getCommonInfo(null,
					function(result:Result):void {
						callback(new SessionResult(sessionID));
					});
			}
		}
		
		public function fetchVersion(sessionID:String,callback:Function):void {
			if(commonInfo) {
				SyncoUtil.callAsync(callback,[new DataResult(commonInfo.version.toString())]);
			}
			else {
				getCommonInfo(sessionID,
					function(result:Result):void {
						callback(new DataResult(commonInfo?commonInfo.version.toString():null));
					});
			}
		}
	}
}