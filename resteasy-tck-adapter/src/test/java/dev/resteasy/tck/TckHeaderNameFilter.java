/*
 * Copyright The RESTEasy Authors
 * SPDX-License-Identifier: Apache-2.0
 */

package dev.resteasy.tck;

import java.util.List;

import jakarta.ws.rs.client.ClientRequestContext;
import jakarta.ws.rs.client.ClientResponseContext;
import jakarta.ws.rs.client.ClientResponseFilter;
import jakarta.ws.rs.core.MultivaluedMap;

/**
 * Restores the case of the response header names the TCK looks up case-sensitively.
 * <p>
 * RFC 9110 section 5.1 states that &quot;Field names are case-insensitive&quot;, so the client can receive the names in
 * a different case. This filter can be removed once the TCK compares header names case-insensitively.
 * </p>
 *
 * @author <a href="mailto:jperkins@ibm.com">James R. Perkins</a>
 */
public class TckHeaderNameFilter implements ClientResponseFilter {
    // Header names the TCK looks up case-sensitively
    private static final List<String> NAMES = List.of("Content-Type", "Set-Cookie", "WWW-Authenticate", "CTS-HEAD", "ALLOW");

    @Override
    public void filter(final ClientRequestContext request, final ClientResponseContext response) {
        final MultivaluedMap<String, String> headers = response.getHeaders();
        for (String name : NAMES) {
            // Remove the header if it exists. The header map itself is case-insensitive. If it exists, re-add it with
            // the expected case for the name.
            final List<String> values = headers.remove(name);
            if (values != null) {
                headers.put(name, values);
            }
        }
    }
}
