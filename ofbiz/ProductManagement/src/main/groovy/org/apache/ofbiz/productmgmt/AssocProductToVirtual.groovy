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

import org.apache.ofbiz.base.util.UtilDateTime
import org.apache.ofbiz.service.ServiceUtil

/**
 * assocProductToVirtual service
 *
 * Creates a ProductAssoc record of type PRODUCT_VARIANT linking:
 *   virtualProductId (the virtual parent) → productId (the variant child)
 *
 * Validates:
 *   - Both products exist.
 *   - The virtual product has isVirtual = "Y".
 *   - No duplicate active association already exists.
 */
Map assocProductToVirtual() {
    def productId        = parameters.productId
    def virtualProductId = parameters.virtualProductId

    // --- 1. Validate variant product ---
    def variantProduct = delegator.findOne("Product", [productId: productId], false)
    if (!variantProduct) {
        return ServiceUtil.returnError("Variant product '${productId}' not found.")
    }

    // --- 2. Validate virtual product ---
    def virtualProduct = delegator.findOne("Product", [productId: virtualProductId], false)
    if (!virtualProduct) {
        return ServiceUtil.returnError("Virtual product '${virtualProductId}' not found.")
    }
    if (virtualProduct.getString("isVirtual") != "Y") {
        return ServiceUtil.returnError("Product '${virtualProductId}' is not a virtual product (isVirtual must be 'Y').")
    }

    // --- 3. Check for existing active association ---
    def existing = select("productId","productIdTo","productAssocTypeId","fromDate")
                   .from("ProductAssoc")
                   .where([productId: virtualProductId,
                           productIdTo: productId,
                           productAssocTypeId: "PRODUCT_VARIANT"])
                   .filterByDate()
                   .queryFirst()

    if (existing) {
        return ServiceUtil.returnError(
            "An active PRODUCT_VARIANT association already exists from '${virtualProductId}' to '${productId}'.")
    }

    // --- 4. Create ProductAssoc ---
    def now = UtilDateTime.nowTimestamp()
    def assoc = delegator.makeValue("ProductAssoc")
    assoc.set("productId",            virtualProductId)   // the virtual product is the parent
    assoc.set("productIdTo",          productId)          // the variant is the child
    assoc.set("productAssocTypeId",   "PRODUCT_VARIANT")
    assoc.set("fromDate",             now)
    delegator.create(assoc)

    // Mark the variant as isVariant = "Y"
    variantProduct.set("isVariant", "Y")
    variantProduct.store()

    logInfo("Created PRODUCT_VARIANT assoc: virtualProductId=${virtualProductId} -> productId=${productId}")
    return ServiceUtil.returnSuccess() + [fromDate: now]
}

assocProductToVirtual()
