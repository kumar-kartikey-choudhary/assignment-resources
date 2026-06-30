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
import org.apache.ofbiz.service.ServiceUtil

/**
 * createProduct service
 *
 * 1. Calls findProduct to check for name uniqueness (name must be unique per business rule).
 * 2. Creates a Product record using the entity engine (delegator.create).
 * 3. Creates a ProductCategoryMember to link the product to the given category.
 * 4. Creates a ProductPrice record (LIST_PRICE) with the provided price.
 */
Map createProduct() {
    def productName       = parameters.productName
    def productCategoryId = parameters.productCategoryId
    def price             = parameters.price
    def currencyUomId     = parameters.currencyUomId ?: "USD"
    def productTypeId     = parameters.productTypeId  ?: "FINISHED_GOOD"

    // --- 1. Uniqueness check via findProduct ---
    def findResult = runService("findProduct", [productName: productName])
    if (ServiceUtil.isError(findResult)) {
        return findResult
    }
    def existingList = findResult.productList
    if (existingList) {
        return ServiceUtil.returnError("A product with the name '${productName}' already exists. Product names must be unique.")
    }

    // --- 2. Check that the category exists ---
    def category = delegator.findOne("ProductCategory", [productCategoryId: productCategoryId], false)
    if (!category) {
        return ServiceUtil.returnError("ProductCategory '${productCategoryId}' not found.")
    }

    // --- 3. Create the Product ---
    def productId = delegator.getNextSeqId("Product")
    def now = UtilDateTime.nowTimestamp()

    def product = delegator.makeValue("Product")
    product.set("productId",           productId)
    product.set("productTypeId",       productTypeId)
    product.set("productName",         productName)
    product.set("internalName",        parameters.internalName ?: productName)
    product.set("description",         parameters.description)
    product.set("brandName",           parameters.brandName)
    product.set("isVirtual",           "N")
    product.set("isVariant",           "N")
    product.set("createdDate",         now)
    product.set("lastModifiedDate",    now)
    product.set("createdByUserLogin",  userLogin?.getString("userLoginId"))
    product.set("lastModifiedByUserLogin", userLogin?.getString("userLoginId"))
    delegator.create(product)

    // --- 4. Create ProductCategoryMember ---
    def catMember = delegator.makeValue("ProductCategoryMember")
    catMember.set("productCategoryId", productCategoryId)
    catMember.set("productId",         productId)
    catMember.set("fromDate",          now)
    delegator.create(catMember)

    // --- 5. Create ProductPrice (LIST_PRICE) ---
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

    logInfo("Created product productId=${productId} name='${productName}'")

    return ServiceUtil.returnSuccess() + [productId: productId]
}

createProduct()
