package com.adobe.connect.synco.results
{
	import com.synco.script.Result;
	
	import flash.display.BitmapData;
	
	public class ImageResult extends Result
	{
		public var image:BitmapData;
		public function ImageResult(image:BitmapData)
		{
			super(image!=null);
			this.image = image;
		}
	}
}