/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package org.apache.ofbiz.productmgmt

import org.apache.ofbiz.service.ServiceUtil

/**
 * updateProductVariant service
 *
 * Updates an existing ProductAssoc (PRODUCT_VARIANT type) between a virtual
 * product and a variant product, identified by the composite PK:
 *   (productId=virtualProductId, productIdTo=productId, productAssocTypeId=PRODUCT_VARIANT, fromDate)
 *
 * Allows updating: thruDate, sequenceNum, reason.
 */
Map updateProductVariant() {
    def productId        = parameters.productId         // variant
    def virtualProductId = parameters.virtualProductId  // virtual parent
    def fromDate         = parameters.fromDate

    // --- 1. Validate the association exists ---
    def assoc = delegator.findOne("ProductAssoc",
        [productId: virtualProductId,
         productIdTo: productId,
         productAssocTypeId: "PRODUCT_VARIANT",
         fromDate: fromDate], false)

    if (!assoc) {
        return ServiceUtil.returnError(
            "No PRODUCT_VARIANT association found from virtualProduct '${virtualProductId}' " +
            "to variant '${productId}' with fromDate '${fromDate}'.")
    }

    // --- 2. Apply updates ---
    def changed = false
    if (parameters.thruDate != null) {
        assoc.set("thruDate", parameters.thruDate)
        changed = true
    }
    if (parameters.sequenceNum != null) {
        assoc.set("sequenceNum", parameters.sequenceNum)
        changed = true
    }
    if (parameters.reason) {
        assoc.set("reason", parameters.reason)
        changed = true
    }

    if (changed) {
        assoc.store()
        logInfo("Updated PRODUCT_VARIANT assoc: virtualProductId=${virtualProductId} -> productId=${productId}")
    }

    return ServiceUtil.returnSuccess()
}

updateProductVariant()
