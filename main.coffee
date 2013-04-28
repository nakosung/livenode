express = require('express')
sockjs = require('sockjs')
http = require('http')
_ = require('underscore')
events = require('events')
async = require('async')

class Collection extends events.EventEmitter
	constructor : ->
		@set = {}
		@nextId = 0
	add : (id,o) ->
		if _.isUndefined(o) 
			o = id
			o.id ?= @nextId++
			id = o.id 			
		@set[id] = o
		@emit 'add', id, o
	get : (id) ->
		@set[id]
	remove : (id) ->
		if _.isObject(id)
			id = id.id
		o = @set[id]
		throw "Invalid" unless o
		@emit 'remove', id, o
		delete @set[id]
	each : (cb) ->
		cb(k,v) for k,v of @set
	keys : ->
		_.keys(@set)
	values : ->
		_.values(@set)

class ScriptCollection 
	constructor : () ->
		@templates = new Collection()
		@modules = new Collection()

		fs = require('fs')
				
		srcPath = __dirname+'/src'
		libPath = __dirname+'/lib'

		doWithFile = (file) =>
			path = require('path')
			ext = path.extname(file)
			return if ext isnt '.coffee'

			coffee_path = srcPath + '/' + file
			name = path.basename(file,ext)
			js_name = name + '.js'
			js_path = libPath + '/' + js_name

			compileCoffeeScript = (src,dst,cb) ->
				fs.readFile src, 'utf8', (err,text) ->
					coffeescript = require('coffee-script')
					fs.writeFile dst, coffeescript.compile(text), cb
				
			readIt = =>
				compileCoffeeScript coffee_path, js_path, =>
					module_name = __dirname+'/src/'+file
					console.log path.normalize(module_name)
					delete require.cache[path.normalize(module_name)]
					@reg_module name, require(module_name)

			readIt()
			fs.watchFile coffee_path, {interval:1001}, readIt

		fs.readdir srcPath, (path,files) =>
			doWithFile(file) for file in files

	reg_module : (name,module) ->
		old_module = @modules.get(name)
		
		for k,v of module
			@templates.add(k,v)
		
		@modules.add(name,module,old_module)

class Engine extends events.EventEmitter
	constructor : ->
		@objects = new Collection()
		@clients = new Collection()
		@loader = new ScriptCollection()
		@loader.modules.on 'add', (name,module,old_module) =>
			if old_module
				objects = @objects_of_module(old_module)
				for o in objects
					new_prototype = @loader.templates[o.__proto__.constructor.name].prototype
					old_version = o.version()
					o.__proto__ = new_prototype
					o.upgrade?(old_version)		
			
			@clients.each (id,client) =>
				client.push_module(name)

		@clients.on 'add', (id,client) =>			
			client.log("good day commander")
			async.map @loader.modules.keys(), ((x,cb) -> client.push_module(x,cb)), (err,result) =>
				client.log("YOU ARE READY")
				
	objects_of_module : (module) ->
		result = []
		@objects.each (id,o) =>
			for c in _.values(module)
				if o instanceof c
					result.push(o)
		result
			
	create : (type,args...) ->
		prototype = @loader.templates.get(type)
		throw "unknown class" unless prototype

		o = new (prototype)(@,args...)
		@objects.add(o)
		o
	
class Client extends events.EventEmitter
	constructor: (@engine,@conn) ->
		@engine.clients.add(@)
		@conn.on 'close', =>
			@close()

		@conn.on 'data', (msg) =>
			json = JSON.parse(msg)			
			@emit 'src', json.src if json.src?

	close: ->
		@engine.clients.remove(@)

	log : (msg) ->
		@write {log:msg}

	write : (json) ->
		@conn.write JSON.stringify(json)

	push_module : (name,cb) ->
		src = "/lib/#{name}.js"
		@log "pushing module #{name}"
		@on 'src', (fin) =>			
			cb?() if fin == src			
		@write {src:src}

engine = new Engine()
world = null

engine.loader.modules.on 'add', (name,module) ->
	console.log "module #{name} loaded"
	world = engine.create('Object') unless world

echo = sockjs.createServer()
echo.on 'connection', (conn) ->
	new Client(engine,conn)	
	
app = express()
app.use '/', express.static(__dirname+'/public')
app.use '/lib', express.static(__dirname+'/lib')

server = http.createServer app
echo.installHandlers server, {prefix:'/echo'}
server.listen 3000

process.once 'SIGUSR2', ->	 
	console.log 'SIGUSR2'
	for conn in conns
		conn.write 'SIGUSR2'
	process.kill process.pid, 'SIGUSR2'

