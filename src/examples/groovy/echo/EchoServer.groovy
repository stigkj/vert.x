package echo

import org.vertx.groovy.core.net.NetServer

println "Starting server"

server = new NetServer().connectHandler { socket ->
  socket.dataHandler { buffer ->
    socket.write buffer
  }
}.listen(8080)


void vertxStop() {
  println "vertxStop called"
  server.close()
}


