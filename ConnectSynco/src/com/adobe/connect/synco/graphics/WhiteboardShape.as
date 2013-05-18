package com.adobe.connect.synco.graphics
{
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class WhiteboardShape
	{
		public var id:String;
		public var depth:Number;
		public var thickness:Number;
		public var strokeColor:String;
		public var fillColor:String;
		public var alpha:Number;
		public var commands:Vector.<int> = new Vector.<int>(); 
		public var data:Vector.<Number> = new Vector.<Number>();
		public var htmlText:String;
		public var position:Point = new Point();
		
		public function WhiteboardShape()
		{
		}
		
		public function clear():void {
			thickness = 0;
			strokeColor = null;
			fillColor = null;
			alpha = 1;
			commands = new Vector.<int>();
			data = new Vector.<Number>();
		}
		
		public function setPosition(x:Number,y:Number):void {
			position.setTo(x,y);
		}
		
		public function lineStyle(thickness:Number,color:String,alpha:Number):void {
			this.thickness = thickness;
			this.strokeColor = color;
			this.alpha = alpha;
		}
		
		public function fill(color:String):void {
			fillColor = color;
		}
		
		public function moveTo(x:Number,y:Number):void {
			commands.push(1);
			data.push(x,y);
		}
		
		public function lineTo(x:Number,y:Number):void {
			commands.push(2);
			data.push(x,y);
		}

		public function getSprite(container:Sprite):Sprite {
			var sprite:Sprite = container.getChildByName(id) as Sprite;
			if(!sprite) {
				sprite = new Sprite() as Sprite;
				sprite.name = id;
				container.addChild(sprite);
			}
			return sprite;
		}
		
		public function draw(container:Sprite):void {
			var child:Sprite = getSprite(container);
			child.x = position.x;
			child.y = position.y;
			child.graphics.clear();
			if(thickness)
				child.graphics.lineStyle(thickness,parseInt(strokeColor.substr(1),16),alpha);
			if(fillColor) {
				child.graphics.beginFill(parseInt(fillColor.substr(1),16),alpha);
			}
			child.graphics.drawPath(commands,data);
			if(fillColor) {
				child.graphics.endFill();
			}
			if(htmlText)
				drawText(child);
		}
		
		private function drawText(sprite:Sprite):void {
			var tf:TextField = sprite.getChildByName("text") as TextField;
			if(htmlText && htmlText.length) {
				if(!tf) {
					tf = sprite.addChild(new TextField()) as TextField;
					tf.autoSize = TextFieldAutoSize.LEFT;
					tf.name = "text";
				}
				tf.text = "";
				tf.htmlText = htmlText;
				if(commands.length) {
					var rect:Rectangle = sprite.getRect(sprite);
					tf.x = rect.x+rect.width/2 + -tf.width/2;
					tf.y = rect.y+rect.height/2 + -tf.height/2;
				}
			}
			else if(tf) {
				sprite.removeChild(tf);
			}
		}
		
		public function toObject():Object {
			var path:Array = [];
			for(var i:int=0;i<commands.length;i++) {
				path.push([commands[i]==1?'M':'L',Math.round(data[i*2]+position.x),Math.round(data[i*2+1]+position.y)]);
			}
			return {id:id, depth:depth, thickness:thickness, strokeColor:strokeColor, fillColor:fillColor, alpha:alpha, path:path };
		}
		
	}
}