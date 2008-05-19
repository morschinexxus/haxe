package unit;

class Test {

	public function new() {
	}

	function eq<T>( v : T, v2 : T, ?pos : haxe.PosInfos ) {
		count++;
		if( v != v2 ) report(v+" should be "+v2,pos);
	}

	function exc( f : Void -> Void, ?pos : haxe.PosInfos ) {
		count++;
		try {
			f();
			report("No exception occured",pos);
		} catch( e : Dynamic ) {
		}
	}

	function unspec( f : Void -> Void, ?pos : haxe.PosInfos ) {
		count++;
		try {
			f();
		} catch( e : Dynamic ) {
		}
	}

	function allow<T>( v : T, values : Array<T>, ?pos : haxe.PosInfos ) {
		count++;
		for( v2 in values )
			if( v == v2 )
				return;
		report(v+" not in "+Std.string(values),pos);
	}

	function infos( m : String ) {
		reportInfos = m;
	}

	function async<Args,T>( f : Args -> (T -> Void) -> Void, args : Args, v : T, ?pos : haxe.PosInfos ) {
		asyncWaits.push(pos);
		f(args,function(v2) {
			count++;
			if( !asyncWaits.remove(pos) ) {
				report("Double async result",pos);
				return;
			}
			if( v != v2 )
				report(v2+" should be "+v,pos);
			checkDone();
		});
	}

	function asyncExc<Args>( seterror : (Dynamic -> Void) -> Void, f : Args -> (Dynamic -> Void) -> Void, args : Args, ?pos : haxe.PosInfos ) {
		asyncWaits.push(pos);
		seterror(function(e) {
			count++;
			if( !asyncWaits.remove(pos) )
				report("Multiple async events",pos);
		});
		f(args,function(v) {
			count++;
			if( asyncWaits.remove(pos) )
				report("No exception occured",pos);
			else
				report("Multiple async events",pos);
		});
	}

	static var count = 0;
	static var reportInfos = null;
	static var reportCount = 0;
	static var checkCount = 0;
	static var asyncWaits = new Array<haxe.PosInfos>();

	dynamic static function report( msg : String, pos : haxe.PosInfos ) {
		if( reportInfos != null ) {
			msg += " ("+reportInfos+")";
			reportInfos = null;
		}
		haxe.Log.trace(msg,pos);
		reportCount++;
		if( reportCount == 10 ) {
			trace("Too many errors");
			report = function(msg,pos) {};
		}
	}

	static function checkDone() {
		if( asyncWaits.length == 0 )
			report("DONE ["+count+" tests]",here);
	}

	static function asyncTimeout() {
		for( pos in asyncWaits )
			report("TIMEOUT",pos);
	}

	static function main() {
		#if neko
		if( neko.Web.isModNeko )
			neko.Lib.print("<pre>");
		#else
		haxe.Timer.delay(asyncTimeout,10000);
		#end
		var classes = [
			new TestBytes(),
			new TestInt32(),
			new TestIO(),
			new TestRemoting(),
		];
		var current = null;
		try {
			asyncWaits.push(null);
			for( inst in classes ) {
				current = Type.getClass(inst);
				for( f in Type.getInstanceFields(current) )
					if( f.substr(0,4) == "test" ) {
						Reflect.callMethod(inst,Reflect.field(inst,f),[]);
						reportInfos = null;
					}
			}
			asyncWaits.remove(null);
			checkDone();
		} catch( e : Dynamic ) {
			reportInfos = null;
			var msg = "???";
			var stack = haxe.Stack.toString(haxe.Stack.exceptionStack());
			try msg = Std.string(e) catch( e : Dynamic ) {};
			reportCount = 0;
			report("ABORTED : "+msg+" in "+Type.getClassName(current),here);
			trace("STACK :\n"+stack);
		}
	}

}