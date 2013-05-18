package com.adobe.connect.synco.graphics
{
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;

	public class WhiteboardUtil
	{
		public function WhiteboardUtil()
		{
		}
		
		public function defineShape(shape:Object,wbShape:WhiteboardShape):void {
			wbShape.id = shape.z;
			wbShape.depth = shape.depth;
		}
		
		public function textShape(shape:Object,wbShape:WhiteboardShape):void {
			wbShape.htmlText = escape(shape.htmlText);
		}
		
		private function hex(color:uint):String {
			var str:String = color.toString(16).slice(0,6);
			return '#'+new Array(7-str.length).join('0')+str;
		}
		
		public function rectangleShape(shape:Object,wbShape:WhiteboardShape):void {
			var matrix:Matrix = new Matrix();
			matrix.scale(shape.width,shape.height);
			matrix.rotate(shape.rotation*Math.PI/180);
			
			var corners:Vector.<Point> = new <Point> [
				matrix.transformPoint(new Point(0,0)),
				matrix.transformPoint(new Point(0,1)),
				matrix.transformPoint(new Point(1,1)),
				matrix.transformPoint(new Point(1,0))
			];
			var minX:Number = Infinity, minY:Number = Infinity;
			for each(var point:Point in corners) {
				minX = Math.min(point.x,minX);
				minY = Math.min(point.y,minY);
			}
			matrix = new Matrix();
			matrix.translate(-minX,-minY);
			for(var i:int=0;i<corners.length;i++) {
				corners[i] = matrix.transformPoint(corners[i]);
			}
			
			wbShape.clear();
			wbShape.lineStyle(shape.strokeWeight,hex(shape.strokeCol),shape.alpha);
			if(shape.hasOwnProperty('fillCol'))
				wbShape.fill(hex(shape.fillCol));
			wbShape.moveTo(corners[0].x,corners[0].y);
			corners.push(corners.shift());
			for(i=0;i<corners.length;i++) {
				wbShape.lineTo(corners[i].x,corners[i].y);
			}
		}
		
		public function pencilShape(shape:Object,wbShape:WhiteboardShape):void {
			var child:Sprite;
			var drawPoint:Point = new Point();
			var matrix:Matrix = new Matrix();
			matrix.scale(shape.width,shape.height);
			matrix.rotate(shape.rotation*Math.PI/180);
			
			var corners:Vector.<Point> = new <Point> [
				matrix.transformPoint(new Point(0,0)),
				matrix.transformPoint(new Point(0,1)),
				matrix.transformPoint(new Point(1,0)),
				matrix.transformPoint(new Point(1,1))
			];
			var minX:Number = Infinity, minY:Number = Infinity;
			for each(var point:Point in corners) {
				minX = Math.min(point.x,minX);
				minY = Math.min(point.y,minY);
			}
			matrix.translate(-minX,-minY);
			var points:Vector.<Point> = new Vector.<Point>();
			point = new Point();
			for each(var pt:Object in shape.pts) {
				point.setTo(pt.x,pt.y);
				points.push(matrix.transformPoint(point));
			}
			
			wbShape.clear();
			wbShape.lineStyle(shape.strokeWeight,hex(shape.strokeCol),shape.alpha);
			if(shape.hasOwnProperty('fillCol'))
				wbShape.fill(hex(shape.fillCol));
			wbShape.moveTo(points[0].x,points[0].y);
			for(var i:int=1; i<points.length; i++) {
				wbShape.lineTo(points[i].x,points[i].y);
			}
		}
	}
}