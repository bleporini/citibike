//
// ========================================================================
// Copyright (c) 1995 Mort Bay Consulting Pty Ltd and others.
//
// This program and the accompanying materials are made available under the
// terms of the Eclipse Public License v. 2.0 which is available at
// https://www.eclipse.org/legal/epl-2.0, or the Apache License, Version 2.0
// which is available at https://www.apache.org/licenses/LICENSE-2.0.
//
// SPDX-License-Identifier: EPL-2.0 OR Apache-2.0
// ========================================================================
//

package io.confluent;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.eclipse.jetty.websocket.api.Callback;
import org.eclipse.jetty.websocket.api.Session;
import org.eclipse.jetty.websocket.api.annotations.OnWebSocketClose;
import org.eclipse.jetty.websocket.api.annotations.OnWebSocketError;
import org.eclipse.jetty.websocket.api.annotations.OnWebSocketMessage;
import org.eclipse.jetty.websocket.api.annotations.OnWebSocketOpen;
import org.eclipse.jetty.websocket.api.annotations.WebSocket;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@WebSocket
public class StationsWebSocket {


    private static final Logger LOG = LoggerFactory.getLogger(StationsWebSocket.class);
    private Session session;
    private ObjectMapper mapper = new ObjectMapper();

    @OnWebSocketClose
    public void onWebSocketClose(int statusCode, String reason)
    {
        this.session = null;
        LOG.info("WebSocket Close: {} - {}", statusCode, reason);
    }

    @OnWebSocketOpen
    public void onWebSocketOpen(Session session)
    {
        this.session = session;
        LOG.info("WebSocket Open: {}", session);
        this.session.sendText("You are now connected to " + this.getClass().getName(), Callback.NOOP);
        StationAvailabilityConsumer.register((k,s) -> {
            if(session == null) return;
            try {
                session.sendText(
                        "{\"id\": \"" + k.substring(5, k.length()) + "\", \"station\":" + mapper.writeValueAsString(s) + "}"
                        , Callback.NOOP);
            } catch (JsonProcessingException e) {
                throw new RuntimeException(e);
            }

        });
    }

    @OnWebSocketError
    public void onWebSocketError(Throwable cause) {
        LOG.warn("WebSocket Error",cause);
    }

    @OnWebSocketMessage
    public void onWebSocketText(String message) {
        LOG.info("Message received: {}", message);

    }
}
