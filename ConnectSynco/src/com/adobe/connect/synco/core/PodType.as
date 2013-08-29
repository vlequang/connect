package com.adobe.connect.synco.core
{
	public class PodType
	{
		static public const CUSTOM:String = "CUSTOM";
		static public const PODS:String = "PODS";
		static public const CONTENTDB:String = "CONNECTDB";
		static public const VIDEO:String = "VIDEO";
		static public const VIDEOSTREAM:String = "VIDEOSTREAM";
		static public const CHATMESSAGES:String = "CHATMESSAGES";
		static public const CONTENT:String = "CONTENT";
		static public const CONTENTWHITEBOARD:String = "CONTENTWHITEBOARD";
		static public const WHITEBOARD:String = "WHITEBOARD";
		static public const LAYOUT_LAYOUT:String = "LAYOUT_LAYOUT";
		static public const LAYOUT_SAVEDSTATE:String = "LAYOUT_SAVEDSTATE";
		static public const ROOMSIZE:String = "ROOMSIZE";
		static public const BREAKOUT:String = "BREAKOUT";
		static public const ROOM_BACKGROUND:String = "ROOM_BACKGROUND";
		static public const UNIVOICE:String = "UNIVOICE";
		static public const SCREENSHARE:String = "SCREENSHARE";
		static public const STREAMLIST:String = "STREAMLIST";
		static public const PDF:String = "PDF";
		static public const PPT:String = "PPT";
		static public const ATTENDEES:String = "ATTENDEES";
		static public const POLLQUESTIONS:String = "POLLQUESTIONS";
		static public const RECORDING:String = "RECORDING";
		static public const TELEPHONY:String = "TELEPHONY";
		
		static public const preference:Object = {};
		static private const runOnce:* = setPreferences();
		
		static private function setPreferences():void {
			preference[CUSTOM] =			["public/all/%1"];
			preference[CONTENTDB] =			["presenters/all/ContentDb_so",true,false];
			preference[PODS] =				["presenters/all/gShell_objects",true,false];
			preference[VIDEO] =				["public/all/%1_videoStreamIds",false,false];
			preference[VIDEOSTREAM] =		["public/all/%1",false,false];
			preference[CHATMESSAGES] =		["public/all/%1_message",false,false];
			preference[CONTENT]	=			["presenters/all/%1_Content",true,false];
			preference[CONTENTWHITEBOARD] =	["public/all/%1_WB8_%2",true,false];
			preference[WHITEBOARD] =		["public/all/%1_WB8",true,false]
			preference[LAYOUT_LAYOUT] = 	["presenters/all/FtLayout_layouts",true,false];
			preference[LAYOUT_SAVEDSTATE] = ["presenters/all/FtLayout_savedState",true,false];
			preference[ROOMSIZE] = 			["presenters/all/RoomSize",true,false];
			preference[BREAKOUT] =			["presenters/all/breakout",true,false];
			preference[ROOM_BACKGROUND] =	["presenters/all/room_background",true,false];
			preference[UNIVOICE] = 			["presenters/all/unifiedVoice",false,false];
			preference[SCREENSHARE] = 		["presenters/all/%1_Cam",false,false];
			preference[STREAMLIST] =		["public/all/streamList",false,false];
			preference[PDF] = 				["public/all/%1_pdfContent8",true,false];
			preference[PPT] = 				["presenters/all/%1_PptContent",true,false];
			preference[ATTENDEES] =			["presenters/all/gShell_users",false,false];
			preference[POLLQUESTIONS] =		["public/all/%1_Question",true,false];
			preference[RECORDING] = 		["presenters/all/recorderUi",true,false];
			preference[TELEPHONY] = 		["presenters/all/telephonyConference",false,false];
		}
		
		static public function getSharedObjectName(id:String,type:String,params:Array=null):String {
			if(!preference[type]) {
				throw new Error(type + " is not a recognized type");
			}
			var str:String = preference[type][0];
			if(params) {
				for(var i:int=params.length-1;i>=0;i--) {
					str = str.split("%"+(i+2)).join(params[i]);
				}
			}
			str = str.split("%1").join(id);
			return str;
		}
	}
}