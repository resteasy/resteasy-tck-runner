/*
 * Copyright The RESTEasy Authors
 * SPDX-License-Identifier: Apache-2.0
 */

package dev.resteasy.tck;

import jakarta.ws.rs.core.Feature;
import jakarta.ws.rs.core.FeatureContext;

/**
 *
 * @author <a href="mailto:jperkins@ibm.com">James R. Perkins</a>
 */
public class TckFeature implements Feature {
    @Override
    public boolean configure(final FeatureContext context) {
        context.register(TckHeaderNameFilter.class);
        return true;
    }
}
