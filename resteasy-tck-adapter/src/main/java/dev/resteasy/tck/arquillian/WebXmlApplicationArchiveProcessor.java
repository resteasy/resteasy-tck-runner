/*
 * Copyright The RESTEasy Authors
 * SPDX-License-Identifier: Apache-2.0
 */

package dev.resteasy.tck.arquillian;

import org.jboss.arquillian.container.test.spi.client.deployment.ApplicationArchiveProcessor;
import org.jboss.arquillian.test.spi.TestClass;
import org.jboss.shrinkwrap.api.Archive;
import org.jboss.shrinkwrap.api.asset.Asset;
import org.jboss.shrinkwrap.api.asset.StringAsset;

/**
 * @author <a href="mailto:jperkins@redhat.com">James R. Perkins</a>
 */
public class WebXmlApplicationArchiveProcessor implements ApplicationArchiveProcessor {
    @Override
    public void process(final Archive<?> applicationArchive, final TestClass testClass) {
        if (applicationArchive.getName().equals("MultipartSupportIT.war")) {
            applicationArchive.add(createWebXml(), "WEB-INF/web.xml");
        }
    }

    /**
     * Creates a {@code web.xml} file for the MultipartSupport test.
     *
     * @return a {@code web.xml} file
     */
    public static Asset createWebXml() {
        final String servletName = "jakarta.ws.rs.core.Application";
        final StringBuilder webXml = new StringBuilder()
                .append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
                .append("<web-app xmlns=\"https://jakarta.ee/xml/ns/jakartaee\" \n")
                .append("   xmlns:xsi=\"https://www.w3.org/2001/XMLSchema-instance\" \n")
                .append("   xsi:schemaLocation=\"https://jakarta.ee/xml/ns/jakartaee https://jakarta.ee/xml/ns/jakartaee/web-app_5_0.xsd\"\n")
                .append("   version=\"5.0\">\n")
                .append("    <servlet>\n")
                .append("        <servlet-name>").append(servletName).append("</servlet-name>\n")
                .append("        <servlet-class>org.jboss.resteasy.plugins.server.servlet.HttpServlet30Dispatcher</servlet-class>\n")
                .append("        <init-param>\n")
                .append("            <param-name>jakarta.ws.rs.Application</param-name>\n")
                .append("            <param-value>ee.jakarta.tck.ws.rs.jaxrs31.ee.multipart.MultipartSupportIT$MultipartTestApplication</param-value>\n")
                .append("        </init-param>\n")
                .append("        <init-param>\n")
                .append("            <param-name>resteasy.scanned.resources</param-name>\n")
                .append("            <param-value>ee.jakarta.tck.ws.rs.jaxrs31.ee.multipart.MultipartSupportIT$TestResource</param-value>\n")
                .append("        </init-param>\n")
                .append("        <async-supported>true</async-supported>\n")
                .append("        <multipart-config>\n")
                .append("            <max-file-size>-1</max-file-size>\n")
                .append("            <max-request-size>-1</max-request-size>\n")
                .append("            <file-size-threshold>0</file-size-threshold>\n")
                .append("            <location/>\n")
                .append("        </multipart-config>\n")
                .append("    </servlet>\n")
                .append("    <servlet-mapping>\n")
                .append("        <servlet-name>").append(servletName).append("</servlet-name>\n")
                .append("        <url-pattern>/*</url-pattern>\n")
                .append("    </servlet-mapping>\n")
                .append("</web-app>\n");
        return new StringAsset(webXml.toString());
    }
}
