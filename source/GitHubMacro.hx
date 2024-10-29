import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr.Field;

class GitHubMacro {
	public static macro function run():Array<Field> {
		if (sys.FileSystem.exists('.git') && sys.FileSystem.isDirectory('.git')) {
			Compiler.define('github');

			Compiler.define('github.repo_url', _getRepoUrl());
		}

		return Context.getBuildFields();
	}

	private static inline function _getRepoUrl():String {
		var git = new sys.io.Process('git', ['config', '--get', 'remote.origin.url']);
		var result = Std.string(git.stdout.readAll());
		git.exitCode();
		return result;
	}
}