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
import org.apache.ofbiz.base.util.UtilMisc
import org.apache.ofbiz.entity.condition.EntityCondition
import org.apache.ofbiz.entity.condition.EntityOperator
import org.apache.ofbiz.service.ServiceUtil

/**
 * updateProduct service
 *
 * 1. Validates that the product exists.
 * 2. Optionally updates price (updates existing LIST_PRICE record, or creates one).
 * 3. Optionally applies a product feature (creates ProductFeatureAppl).
 * 4. Optionally updates productName and description on the Product entity.
 */
Map updateProduct() {
    def productId = parameters.productId

    // --- 1. Validate product exists ---
    def product = delegator.findOne("Product", [productId: productId], false)
    if (!product) {
        return ServiceUtil.returnError("Product '${productId}' not found.")
    }

    def now = UtilDateTime.nowTimestamp()
    boolean changed = false

    // --- 2. Update core product fields ---
    def newName = parameters.productName
    if (newName) {
        // Enforce uniqueness: ensure no OTHER product already has this name
        def dupes = select("productId", "productName")
                    .from("Product")
                    .where(EntityCondition.makeCondition("productName", EntityOperator.EQUALS, newName))
                    .queryList()
        def dupe = dupes.find { it.getString("productId") != productId }
        if (dupe) {
            return ServiceUtil.returnError("Another product already has the name '${newName}'. Product names must be unique.")
        }
        product.set("productName", newName)
        changed = true
    }
    if (parameters.description) {
        product.set("description", parameters.description)
        changed = true
    }
    if (parameters.internalName) {
        product.set("internalName", parameters.internalName)
        changed = true
    }
    if (changed) {
        product.set("lastModifiedDate", now)
        product.set("lastModifiedByUserLogin", userLogin?.getString("userLoginId"))
        product.store()
    }

    // --- 3. Update / create a LIST_PRICE ProductPrice if price provided ---
    def price = parameters.price
    if (price != null) {
        def currencyUomId = parameters.currencyUomId ?: "USD"
        // Find an existing active LIST_PRICE for this product
        def priceList = select("productId","productPriceTypeId","productPricePurposeId",
                               "currencyUomId","productStoreGroupId","fromDate","thruDate","price")
                        .from("ProductPrice")
                        .where([productId: productId,
                                productPriceTypeId: "LIST_PRICE",
                                currencyUomId: currencyUomId,
                                productPricePurposeId: "PURCHASE",
                                productStoreGroupId: "_NA_"])
                        .filterByDate()
                        .queryList()

        if (priceList) {
            // Update the first active price row
            def priceRecord = priceList[0]
            priceRecord.set("price", price)
            priceRecord.set("lastModifiedDate", now)
            priceRecord.set("lastModifiedByUserLogin", userLogin?.getString("userLoginId"))
            priceRecord.store()
        } else {
            // Create a new price record
            def productPrice = delegator.makeValue("ProductPrice")
            productPrice.set("productId",              productId)
            productPrice.set("productPriceTypeId",     "LIST_PRICE")
            productPrice.set("productPricePurposeId",  "PURCHASE")
            productPrice.set("currencyUomId",          currencyUomId)
            productPrice.set("productStoreGroupId",    "_NA_")
            productPrice.set("fromDate",               now)
            productPrice.set("price",                  price)
            productPrice.set("createdDate",            now)
            productPrice.set("lastModifiedDate",       now)
            productPrice.set("createdByUserLogin",     userLogin?.getString("userLoginId"))
            productPrice.set("lastModifiedByUserLogin", userLogin?.getString("userLoginId"))
            delegator.create(productPrice)
        }
    }

    // --- 4. Apply a product feature if provided ---
    def productFeatureId = parameters.productFeatureId
    if (productFeatureId) {
        // Validate feature exists
        def feature = delegator.findOne("ProductFeature", [productFeatureId: productFeatureId], false)
        if (!feature) {
            return ServiceUtil.returnError("ProductFeature '${productFeatureId}' not found.")
        }

        def featureApplTypeId = parameters.productFeatureApplTypeId ?: "STANDARD_FEATURE"

        // Check for existing active applicability
        def existing = select("productId","productFeatureId","fromDate")
                       .from("ProductFeatureAppl")
                       .where([productId: productId, productFeatureId: productFeatureId])
                       .filterByDate()
                       .queryFirst()

        if (!existing) {
            def featureAppl = delegator.makeValue("ProductFeatureAppl")
            featureAppl.set("productId",              productId)
            featureAppl.set("productFeatureId",       productFeatureId)
            featureAppl.set("productFeatureApplTypeId", featureApplTypeId)
            featureAppl.set("fromDate",               now)
            delegator.create(featureAppl)
        }
    }

    logInfo("Updated product productId=${productId}")
    return ServiceUtil.returnSuccess()
}

updateProduct()
