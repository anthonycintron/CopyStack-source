package {
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeApplication;
	import flash.display.Bitmap;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	import org.osmf.utils.BinarySearch;

	[SWF(frameRate=24,height="200",width="200",backgroundColor="0x000000")]
	public class CopyStack extends Sprite {
	
		private var debugTxt:TextField;
		private var buffer:Vector.<String>;
		private var numBuffer:int = 5;
		private var txtFormat:TextFormat;
		
		[Embed(source="imgs/copyStack-flat-bckgrnd.png")]
		private var BackgrndAsset:Class;
		
		public function CopyStack()
		{
			setup();
			styleFormat();

		}
		
		private function styleFormat():void
		{
		
			txtFormat = new TextFormat();
			txtFormat.color = 0xcccccc;
			txtFormat.size = 13;
			
			debugTxt = new TextField();
			debugTxt.border = false;
			debugTxt.width = 345;
			debugTxt.height = 200;
			debugTxt.x = 10;
			debugTxt.y = 140;
			debugTxt.wordWrap = true;
			debugTxt.defaultTextFormat = txtFormat;
			addChild(debugTxt);
			
		}
		
		private function setup():void
		{
			visible = false;
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			//bckgrnd
			var bckgrnd:Sprite = new Sprite();
			addChild(bckgrnd);
			bckgrnd.alpha = .9;
			
			var bitmp:Bitmap = new BackgrndAsset();
			bckgrnd.addChild(bitmp);
			
			buffer = new Vector.<String>();

			addEventListener(Event.ENTER_FRAME, checkSystem);
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private var poppedClipboard:String;
		
		protected function onKeyUp(e:KeyboardEvent):void
		{
			
			var key:int;
			if ( e.altKey && e.shiftKey )
			{
				debugTxt.text = "[ALT] + [SHIFT] + ";
				switch( e.keyCode )
				{
					case 48:
						key = 0;
						break;
					case 49:
						key = 1;
						break;
					case 50:
						key = 2;
						break;
					case 51:
						key = 3;
						break;
					case 52:
						key = 4;
						break;
					case 53:
						key = 5;
						break;
				}
				
				
				// set to clipboard
				setCliboard(key);
				
			
				// pop from list
				poppedClipboard = buffer[key];
				buffer.splice(key, 1);
				
				showList();
			}
			
			
			if ( e.altKey && e.keyCode == 67 )
				clear();
			
			visible = false;
		}
		
		private var _list:Sprite;
		
		private function showList():void
		{
			removeChildren(_list);
			
			_list = new Sprite();
			_list.x = 5;
			_list.y = 10;
			addChild(_list);
			
			if ( buffer.length > 0 )
				renderListItem();
		}
		
		/**
		 *
		 * removes child sprites within a main sprite.
		 */
		private function removeChildren(value:Sprite):void
		{	
			if ( value == null )
			return;
			
			while(value.numChildren)
			{
				value.removeChildAt(0);
			}
		}

		/**
		 * clear the stack list.
		 */
		private function clear():void
		{
			Clipboard.generalClipboard.clearData(ClipboardFormats.TEXT_FORMAT);
			debugTxt.text = "Copy Stack is empty.";
			buffer = new Vector.<String>();
		}
		
		
		/**
		 * render each item within the copy stack
		 */
		private function renderListItem():void
		{
			for ( var i:int = 0; i < buffer.length; i++ )
			{
				var item:Sprite = new Sprite();
				item.graphics.lineStyle(1, 0x333333);
				item.graphics.beginFill(0x333333,.9);
				item.graphics.drawRect(0,0, 337, 20);
				item.name = String(i);
				_list.addChild(item);
				
				if ( i != 0 )
				{
					var num:int = i - 1;
					item.y = (_list.getChildAt(num).y + 30);
				}
				
				var copyTxt:TextField = new TextField();
				copyTxt.defaultTextFormat = txtFormat;
				copyTxt.text = "["+i+"] " + buffer[i];
				copyTxt.x = 5;
				copyTxt.width = 350;
				item.addChild(copyTxt);	
			}
		}
		
		
		/**
		 * continuously check to see if there is a new clipboard item. 
		 * @param e
		 * 
		 */		
		private function checkSystem(e:Event):void
		{
			if ( !Clipboard.generalClipboard.hasFormat(ClipboardFormats.TEXT_FORMAT) )
				return;
			
			var currentClipboard:String = Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT).toString();
			
			if ( buffer.length == 0 )
			{
				pushToBuffer(currentClipboard);	
			}
			else if ( buffer.length > 0 && ((buffer[0]) != currentClipboard ) && (poppedClipboard != currentClipboard) )
			{
				trace("Last clipboard item does not match current clipboard")
				pushToBuffer(currentClipboard);	
			}
		}
		
		/**
		 *
		 * push new copy to clipboard.
		 */
		private var _timer:Timer;
		
		private function pushToBuffer(currentClipboard:String):void
		{
			
			if ( buffer.length >= numBuffer)
				return;
				
			if ( debugTxt.text == "Copy Stack is empty." )
				debugTxt.text = "";
			
			visible = true;
			
			// push new item  into history.
			buffer.unshift(currentClipboard);
			
			showList();
			
			hide();
		}
		
		private function hide():void
		{
			_timer = new Timer(800,1);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);
			_timer.start();
		}
		
		private function onTimerComplete(e:TimerEvent):void
		{
			_timer.removeEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);
			visible = false;
		}
		
		private function setCliboard(key:int):void
		{
			Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, buffer[key]);
			debugTxt.text = "";
		}
		
		private function onAddedToStage(e:Event):void
		{
			stage.nativeWindow.alwaysInFront = true;
		}
		
		protected function onKeyDown(e:KeyboardEvent):void
		{
			visible = true;
			showList();
		}
		
	}
}

