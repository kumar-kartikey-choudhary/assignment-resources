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

import org.apache.ofbiz.base.util.UtilMisc
import org.apache.ofbiz.entity.condition.EntityCondition
import org.apache.ofbiz.entity.condition.EntityFieldValue
import org.apache.ofbiz.entity.condition.EntityFunction
import org.apache.ofbiz.entity.condition.EntityOperator
import org.apache.ofbiz.entity.util.EntityUtil
import org.apache.ofbiz.service.ServiceUtil

/**
 * findProduct service
 *
 * Searches the FindProductView view-entity applying optional filters:
 *   - productId          : exact or partial case-insensitive match
 *   - productName        : partial case-insensitive match
 *   - productCategoryId  : exact match
 *   - minPrice/maxPrice  : price range (applied to LIST_PRICE rows)
 *   - productFeatureTypeId : exact match on feature type
 *   - productFeatureId   : exact match on feature
 *
 * Returns a deduplicated list of matching products.
 */
Map findProduct() {
    def andExprs = []

    // --- productId filter (partial case-insensitive) ---
    def prodIdParam = parameters.productId
    if (prodIdParam) {
        andExprs << EntityCondition.makeCondition(
            EntityFunction.upper(EntityFieldValue.makeFieldValue("productId")),
            EntityOperator.LIKE,
            "%" + prodIdParam.toUpperCase() + "%"
        )
    }

    // --- productName filter (partial case-insensitive) ---
    def productNameParam = parameters.productName
    if (productNameParam) {
        andExprs << EntityCondition.makeCondition(
            EntityFunction.upper(EntityFieldValue.makeFieldValue("productName")),
            EntityOperator.LIKE,
            "%" + productNameParam.toUpperCase() + "%"
        )
    }

    // --- productCategoryId filter (exact) ---
    def catId = parameters.productCategoryId
    if (catId) {
        andExprs << EntityCondition.makeCondition("productCategoryId", EntityOperator.EQUALS, catId)
    }

    // --- price range filter (on LIST_PRICE rows only) ---
    def minPrice = parameters.minPrice
    def maxPrice = parameters.maxPrice
    if (minPrice != null || maxPrice != null) {
        // restrict to LIST_PRICE price type rows
        andExprs << EntityCondition.makeCondition("productPriceTypeId", EntityOperator.EQUALS, "LIST_PRICE")
        if (minPrice != null) {
            andExprs << EntityCondition.makeCondition("price", EntityOperator.GREATER_THAN_EQUAL_TO, minPrice)
        }
        if (maxPrice != null) {
            andExprs << EntityCondition.makeCondition("price", EntityOperator.LESS_THAN_EQUAL_TO, maxPrice)
        }
    }

    // --- productFeatureTypeId filter ---
    def featureTypeId = parameters.productFeatureTypeId
    if (featureTypeId) {
        andExprs << EntityCondition.makeCondition("productFeatureTypeId", EntityOperator.EQUALS, featureTypeId)
    }

    // --- productFeatureId filter ---
    def featureId = parameters.productFeatureId
    if (featureId) {
        andExprs << EntityCondition.makeCondition("productFeatureId", EntityOperator.EQUALS, featureId)
    }

    // Build combined condition
    def condition = andExprs ? EntityCondition.makeCondition(andExprs, EntityOperator.AND) : null

    // Query FindProductView
    def qb = select("productId", "productName", "internalName", "productTypeId",
                     "productCategoryId", "price", "currencyUomId", "productPriceTypeId",
                     "productFeatureId", "productFeatureTypeId", "featureDescription",
                     "isVirtual", "isVariant", "brandName")
              .from("FindProductView")

    if (condition) {
        qb = qb.where(condition)
    }

    def rawList = qb.queryList()

    // Deduplicate by productId (view can return multiple rows per product due to joins)
    def seen = [] as Set
    def productList = rawList.findAll { row ->
        seen.add(row.getString("productId"))
    }

    return ServiceUtil.returnSuccess() + [productList: productList]
}

findProduct()
