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

package org.vertx.java.core.stdio;

import org.vertx.java.core.streams.ReadStream;
import org.vertx.java.core.streams.WriteStream;

/**
 * <p>Provides asynchronous stream wrappers around STDOUT, STDIN and STDERR</p>
 *
 * <p>These wrappers should be used if you want to use STDOUT, STDIN and STDERR in a non blocking way from inside
 * an event loop.</p>
 *
 * @author <a href="http://tfox.org">Tim Fox</a>
 */
public class Stdio {

  /**
   * Returns a {@code ReadStream} wrapped around STDIN
   */
  public static ReadStream createInputStream() {
    return new InStream(System.in);
  }

  /**
   * Returns a {@code WriteStream} wrapped around STDOUT
   */
  public static WriteStream createOutputStream() {
    return new OutStream(System.out);
  }

  /**
   * Returns a {@code WriteStream} wrapped around STDERR
   */
  public static WriteStream createErrorStream() {
    return new OutStream(System.err);
  }

}
