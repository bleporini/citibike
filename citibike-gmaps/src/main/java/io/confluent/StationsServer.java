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

import java.net.URL;
import java.util.Objects;

import org.eclipse.jetty.ee10.servlet.DefaultServlet;
import org.eclipse.jetty.ee10.servlet.ServletContextHandler;
import org.eclipse.jetty.ee10.servlet.ServletHolder;
import org.eclipse.jetty.ee10.websocket.server.config.JettyWebSocketServletContainerInitializer;
import org.eclipse.jetty.server.Server;

public class StationsServer
{
    public static void main(String[] args) throws Exception
    {
        StationAvailabilityConsumer.start();
        Server server = StationsServer.newServer(8080);
        server.start();
        server.join();
    }

    public static Server newServer(int port)
    {
        Server server = new Server(port);

        ServletContextHandler context = new ServletContextHandler(ServletContextHandler.SESSIONS);
        context.setContextPath("/");
        server.setHandler(context);

        // Add websocket servlet
        JettyWebSocketServletContainerInitializer.configure(context, null);
        ServletHolder wsHolder = new ServletHolder("stations", new StationsWebSocketServlet());
        context.addServlet(wsHolder, "/stations");

        URL urlStatics = Thread.currentThread().getContextClassLoader().getResource("static/index.html");
        Objects.requireNonNull(urlStatics, "Unable to find index.html in classpath");
        String urlBase = urlStatics.toExternalForm().replaceFirst("/[^/]*$", "/");
        ServletHolder defHolder = new ServletHolder("default", new DefaultServlet());
        defHolder.setInitParameter("resourceBase", urlBase);
        defHolder.setInitParameter("dirAllowed", "true");
        context.addServlet(defHolder, "/");

        return server;
    }
}
