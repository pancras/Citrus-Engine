package citrus.input.controllers 
{

	import citrus.input.InputController;

	import flash.events.AccelerometerEvent;
	import flash.sensors.Accelerometer;
	
	public class Accelerometer extends InputController
	{
		private var _accel: flash.sensors.Accelerometer;
		
		//current accel
		private var _a:Object = { x:0, y:0, z:0 };
		//target accel
		private var _t:Object = { x:0, y:0, z:0 };
		
		//rotation
		private var _rot:Object = { x:0 , y:0 , z:0 };
		//previous accel
		private var _prevRot:Object = { x:0 , y:0 , z:0 };
		
		//only start calculating when received first events from device.
		private var receivedFirstAccelUpdate:Boolean = false;
		
		/**
		 * Angle inside which no action is triggered, representing the "center" or the "idle position".
		 * the more this angle is big, the more the device needs to be rotated to start triggering actions.
		 */
		public var idleAngleZ:Number = Math.PI / 8;
		
		/**
		 * Angle inside which no action is triggered, representing the "center" or the "idle position".
		 * the more this angle is big, the more the device needs to be rotated to start triggering actions.
		 */
		public var idleAngleX:Number = Math.PI / 6;
		
		/**
		 * Set this to offset the Z rotation calculations :
		 */
		public var offsetZAngle:Number = 0;
		
		/**
		 * Set this to offset the Y rotation calculations :
		 */
		public var offsetYAngle:Number = 0;
		
		/**
		 * Set this to offset the X rotation calculations :
		 */
		public var offsetXAngle:Number = -Math.PI/2 + Math.PI/4;
		
		/**
		 * easing of the accelerometer's X value.
		 */
		public var easingX:Number = 0.5;
		/**
		 * easing of the accelerometer's Y value.
		 */
		public var easingY:Number = 0.5;
		/**
		 * easing of the accelerometer's Z value.
		 */
		public var easingZ:Number = 0.5;
		
		/**
		 * action name for the rotation on the X axis.
		 */
		public static const ROT_X:String = "rotX";
		/**
		 * action name for the rotation on the Y axis.
		 */
		public static const ROT_Y:String = "rotY";
		/**
		 * action name for the rotation on the Z axis.
		 */
		public static const ROT_Z:String = "rotZ";
		
		/**
		 * action name for the raw accelerometer X value.
		 */
		public static const RAW_X:String = "rawX";
		/**
		 * action name for the raw accelerometer Y value.
		 */
		public static const RAW_Y:String = "rawY";
		/**
		 * action name for the raw accelerometer Z value.
		 */
		public static const RAW_Z:String = "rawZ";
		
		/**
		 * send the new raw values on each frame.
		 */
		public var triggerRawValues:Boolean = false;
		/**
		 * send the new rotation values on each frame in radian.
		 */
		public var triggerAxisRotation:Boolean = true;
		
		/**
		 * if true, on each update values will be computed to send custom Actions (such as left right up down by default)
		 */
		public var triggerActions:Boolean = true;
		
		public function Accelerometer(name:String,params:Object) 
		{
			super(name, params);
			if (! flash.sensors.Accelerometer.isSupported)
			{
				trace(this, "Accelerometer is not supported");
				enabled = false;
			}
			else
			{
				_accel = new  flash.sensors.Accelerometer();
				_accel.addEventListener(AccelerometerEvent.UPDATE, onAccelerometerUpdate);
			}
			
		}
		
		/*
		 * This updates the target values of acceleration which will be eased on each frame through the update function.
		 */
		public function onAccelerometerUpdate(e:AccelerometerEvent):void
		{
			_t.x = e.accelerationX;
			_t.y = e.accelerationY;
			_t.z = e.accelerationZ;
			
			receivedFirstAccelUpdate = true;
		}
		
		override public function update():void
		{
			if (!receivedFirstAccelUpdate)
				return;
			
			//ease values
			_a.x += (_t.x -_a.x) * easingX;
			_a.y += (_t.y -_a.y) * easingY;
			_a.z += (_t.z -_a.z) * easingZ;
			
			_rot.x = Math.atan2(_a.y, _a.z) + offsetXAngle;
			_rot.y = Math.atan2(_a.x, _a.z) + offsetYAngle;
			_rot.z = Math.atan2(_a.x, _a.y) + offsetZAngle;
			
			if (triggerRawValues)
			{
				triggerVALUECHANGE(RAW_X, _a.x);
				triggerVALUECHANGE(RAW_Y, _a.y);
				triggerVALUECHANGE(RAW_Z, _a.z);
			}	
			
			if (triggerAxisRotation)
			{
				triggerVALUECHANGE(ROT_X, _rot.x);
				triggerVALUECHANGE(ROT_Y, _rot.y);
				triggerVALUECHANGE(ROT_Z, _rot.z);
			}
			
			if (triggerActions)
				customActions();
				
			_prevRot.x = _rot.x;
			_prevRot.y = _rot.y;
			_prevRot.z = _rot.z;
			
		}
		
		/**
		 * Override this function to customize actions based on orientation
		 * by default, if triggerActions is set to true, customActions will be called
		 * in which default actions such as left/right/up/down will be triggered
		 * based on the actual rotation of the device:
		 * in landscape mode, pivoting the device to the right will trigger a right action for example.
		 * to make it available in portrait mode, the offsetZAngle can help rotate that calculation by 90° or more
		 * depeding on your screen orientation...
		 * 
		 * this was mostly tested on a fixed landscape orientation setting.
		 */
		protected function customActions():void
		{
			//in idle position on Z
			if (_rot.z < idleAngleZ && _rot.z > - idleAngleZ)
			{
				triggerOFF("left", 0);
				triggerOFF("right", 0);
			}
			else
			{
				//going right
				if (_rot.z < 0 && _rot.z > -Math.PI/2)
				{
					triggerON("right", 1);
					triggerOFF("left", 0);
				}
				
				//going left
				if (_rot.z > 0 && _rot.z < Math.PI / 2)
				{
					triggerON("left", 1);
					triggerOFF("right", 0);
				}
			}
			
			//in idle position on X
			if (_rot.x < idleAngleX && _rot.x > - idleAngleX)
			{
				triggerOFF("jump", 0);
				triggerOFF("down", 0);
			}
			else
			{
				//going up
				if (_rot.x < 0 && _rot.x > -Math.PI/2)
				{
					triggerON("jump", 1);
					triggerOFF("down", 0);
				}
				
				//going down
				if (_rot.x > 0 && _rot.x < Math.PI / 2)
				{
					triggerON("down", 1);
					triggerOFF("jump", 0);
				}
			}
			
			
		}
		
	}

}