/*
 * Copyright 2011 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.vertx.java.core.streams;

import org.vertx.java.core.Handler;
import org.vertx.java.core.buffer.Buffer;

/**
 * <p>Pumps data from a {@link ReadStream} to a {@link WriteStream} and performs flow control where necessary to
 * prevent the write stream from getting overloaded.</p>
 * <p>Instances of this class read bytes from a {@link ReadStream} and write them to a {@link WriteStream}. If data
 * can be read faster than it can be written this could result in the write queue of the {@link WriteStream} growing
 * without bound, eventually causing it to exhaust all available RAM.</p>
 * <p>To prevent this, after each write, instances of this class check whether the write queue of the {@link
 * WriteStream} is full, and if so, the {@link ReadStream} is paused, and a {@code drainHandler} is set on the {@link
 * WriteStream}. When the {@link WriteStream} has processed half of its backlog, the {@code drainHandler} will be
 * called, which results in the pump resuming the {@link ReadStream}.</p>
 * <p>This class can be used to pump from any {@link ReadStream} to any {@link WriteStream},
 * e.g. from an {@link org.vertx.java.core.http.HttpServerRequest} to an {@link org.vertx.java.core.file.AsyncFile},
 * or from {@link org.vertx.java.core.net.NetSocket} to a {@link org.vertx.java.core.http.WebSocket}.</p>
 *
 * @author <a href="http://tfox.org">Tim Fox</a>
 */
public class Pump {
  private final ReadStream readStream;
  private final WriteStream writeStream;

  private int pumped;

  private final Handler<Void> drainHandler = new Handler<Void>() {
    public void handle(Void v) {
      readStream.resume();
    }
  };

  private final Handler<Buffer> dataHandler = new Handler<Buffer>() {
    public void handle(Buffer buffer) {
      writeStream.writeBuffer(buffer);
      pumped += buffer.length();
      if (writeStream.writeQueueFull()) {
        readStream.pause();
        writeStream.drainHandler(drainHandler);
      }
    }
  };

  /**
   * Create a new {@code Pump} with the given {@code ReadStream} and {@code WriteStream}
   */
  public Pump(ReadStream rs, WriteStream ws) {
    this.readStream = rs;
    this.writeStream = ws;
  }

  /**
   * Create a new {@code Pump} with the given {@code ReadStream} and {@code WriteStream}. Set the write queue max size
   * of the write stream to {@code maxWriteQueueSize}
   */
  public Pump(ReadStream rs, WriteStream ws, int maxWriteQueueSize) {
    this(rs, ws);
    this.writeStream.setWriteQueueMaxSize(maxWriteQueueSize);
  }

  /**
   * Set the write queue max size to {@code maxSize}
   */
  public void setWriteQueueMaxSize(int maxSize) {
    this.writeStream.setWriteQueueMaxSize(maxSize);
  }

  /**
   * Start the Pump. The Pump can be started and stopped multiple times.
   */
  public void start() {
    readStream.dataHandler(dataHandler);
  }

  /**
   * Stop the Pump. The Pump can be started and stopped multiple times.
   */
  public void stop() {
    writeStream.drainHandler(null);
    readStream.dataHandler(null);
  }

  /**
   * Return the total number of bytes pumped by this pump.
   */
  public int getBytesPumped() {
    return pumped;
  }

}
