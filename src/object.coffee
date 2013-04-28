class Object
	constructor:(@engine)->
	version:->1
	snapshot:->_.clone(@)
	applySnapshot:(snapshot)->
		for v,k of snapshot
			target = @[k]
	upgrade:(from) ->
		console.log 'upgraded from',from
		console.log "HI hello"
		console.log 'this is the live coding'
 
class Child extends Object
	constructor:(@engine,@hello) ->
	version:->3
	upgrade:(from)->
		super(from)
		console.log 'child says',@hello

target = exports ? window;
target.Object = Object 
target.Child = Child