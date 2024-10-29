import haxe.io.Path;
import haxe.macro.Compiler;
import flixel.util.FlxStringUtil;
import haxe.CallStack;

using StringTools;

class CrashHandler {
	public static inline function init() {
		#if sys
		if (!sys.FileSystem.exists('.temp') || !sys.FileSystem.isDirectory('.temp')) sys.FileSystem.createDirectory('.temp');
		_log = sys.io.File.write('.temp/log');
		#end

		haxe.Log.trace = (v, ?pos) -> {
			var str = haxe.Log.formatOutput(v, pos);
			#if js
			if (js.Syntax.typeof(untyped console) != "undefined" && (untyped console).log != null)
				(untyped console).log(str);
			#elseif lua
			untyped __define_feature__("use._hx_print", _hx_print(str));
			#elseif sys
			_log.writeString(str);
			_log.writeByte(10);

			Sys.println(str);
			#else
			throw new haxe.exceptions.NotImplementedException();
			#end
		}

		#if hl
		hl.Api.setErrorHandler(_onError);
		#else
		openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(openfl.events.UncaughtErrorEvent.UNCAUGHT_ERROR, (e) -> _onError(e.error));
		#end
	}

	private static function _onError(e:Dynamic) {
		var report = _buildReport(e);
		var reportName = 'CrashReport ${Date.now().toString().replace(':', '-')}.txt';
		#if sys
		var reportDir = './crash';
		if (!sys.FileSystem.exists(reportDir) || !sys.FileSystem.isDirectory(reportDir)) sys.FileSystem.createDirectory(reportDir);
		sys.io.File.saveContent(Path.join([reportDir, reportName]), report);
		#elseif js
		var fileRef = new openfl.net.FileReference();
		fileRef.save(report, reportName);
		#end
	}

	#if sys
	private static var _log:sys.io.FileOutput;
	#end
	private static function _buildReport(e:Dynamic):String {
		var b = new StringBuf();

		b.add('$e\n');

		b.add('\nCalled from:\n');
		b.add('${_buildStack()}\n');

		#if hl
		b.add('\nMemory stats:\n');
		var allocMem = 0.0, allocCount = 0.0, curMem = 0.0;
		@:privateAccess hl.Gc._stats(allocMem, allocCount, curMem);
		b.add(' - Allocated memory: ${FlxStringUtil.formatBytes(allocMem)} ($allocMem Bytes)\n');
		b.add(' - Allocations: $allocCount\n');
		b.add(' - Used memory: ${FlxStringUtil.formatBytes(curMem)} ($curMem Bytes)\n');
		#end

		#if github
			b.add('\nGitHub info:\n');
			#if github.repo_url
			b.add(' - Repository URL: ${Compiler.getDefine('github.repo_url')}\n');
			#end
			#if github.run_id
			b.add(' - Build workflow ID: ${Compiler.getDefine('github.run_id')}\n');
			#end
		#end

		#if sys
		b.add('\nLog:\n');
		b.add(sys.io.File.getContent('.temp/log'));
		#end

		return b.toString();
	}

	private static function _buildStack():String {
		var b = new StringBuf();

		var stack = CallStack.exceptionStack(true);
		for (item in stack) b.add('${_item2string(item)}\n');

		return b.toString();
	}

	private static function _item2string(item:StackItem):String {
		return switch item {
			case CFunction: ' - Non-Haxe Function (C Function)';
			case Module(m): ' - Module $m';
			case FilePos(s, file, line, column): ' - $file:$line: \n\t${_item2string(s)}';
			case Method(classname, method): ' - Method $method from $classname';
			case LocalFunction(v): ' - Local Function #$v';
		}
	}
}