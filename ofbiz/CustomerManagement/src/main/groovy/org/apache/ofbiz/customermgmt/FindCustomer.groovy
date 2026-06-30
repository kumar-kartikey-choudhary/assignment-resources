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
package org.apache.ofbiz.customermgmt

import org.apache.ofbiz.entity.condition.EntityCondition
import org.apache.ofbiz.entity.condition.EntityFieldValue
import org.apache.ofbiz.entity.condition.EntityFunction
import org.apache.ofbiz.entity.condition.EntityOperator
import org.apache.ofbiz.service.ServiceUtil

/**
 * findCustomer service
 *
 * Queries FindCustomerView with optional filters.
 * Restricts contact-mechanism purpose rows to:
 *   emailPurposeTypeId  = PRIMARY_EMAIL
 *   phonePurposeTypeId  = PRIMARY_PHONE     (when phone filter requested)
 *   addrPurposeTypeId   = PRIMARY_LOCATION  (when address filter requested)
 *
 * All text matches are case-insensitive partial (LIKE %VALUE%).
 * Deduplicates by partyId before returning.
 */
Map findCustomer() {
    def andExprs = []

    // Always restrict to PRIMARY_EMAIL purpose rows (the uniqueness key)
    andExprs << EntityCondition.makeCondition("emailPurposeTypeId",
                    EntityOperator.EQUALS, "PRIMARY_EMAIL")

    // partyId filter
    def partyIdParam = parameters.partyId
    if (partyIdParam) {
        andExprs << EntityCondition.makeCondition(
            EntityFunction.upper(EntityFieldValue.makeFieldValue("partyId")),
            EntityOperator.LIKE, "%" + partyIdParam.toUpperCase() + "%")
    }

    // firstName filter
    def firstNameParam = parameters.firstName
    if (firstNameParam) {
        andExprs << EntityCondition.makeCondition(
            EntityFunction.upper(EntityFieldValue.makeFieldValue("firstName")),
            EntityOperator.LIKE, "%" + firstNameParam.toUpperCase() + "%")
    }

    // lastName filter
    def lastNameParam = parameters.lastName
    if (lastNameParam) {
        andExprs << EntityCondition.makeCondition(
            EntityFunction.upper(EntityFieldValue.makeFieldValue("lastName")),
            EntityOperator.LIKE, "%" + lastNameParam.toUpperCase() + "%")
    }

    // emailAddress filter (partial, case-insensitive on infoString aliased as emailAddress)
    def emailParam = parameters.emailAddress
    if (emailParam) {
        andExprs << EntityCondition.makeCondition(
            EntityFunction.upper(EntityFieldValue.makeFieldValue("emailAddress")),
            EntityOperator.LIKE, "%" + emailParam.toUpperCase() + "%")
    }

    // contactNumber filter
    def phoneParam = parameters.contactNumber
    if (phoneParam) {
        andExprs << EntityCondition.makeCondition(
            EntityFunction.upper(EntityFieldValue.makeFieldValue("contactNumber")),
            EntityOperator.LIKE, "%" + phoneParam.toUpperCase() + "%")
    }

    // address1 filter
    def addrParam = parameters.address1
    if (addrParam) {
        andExprs << EntityCondition.makeCondition(
            EntityFunction.upper(EntityFieldValue.makeFieldValue("address1")),
            EntityOperator.LIKE, "%" + addrParam.toUpperCase() + "%")
    }

    // city filter
    def cityParam = parameters.city
    if (cityParam) {
        andExprs << EntityCondition.makeCondition(
            EntityFunction.upper(EntityFieldValue.makeFieldValue("city")),
            EntityOperator.LIKE, "%" + cityParam.toUpperCase() + "%")
    }

    def condition = EntityCondition.makeCondition(andExprs, EntityOperator.AND)

    def rawList = select("partyId", "firstName", "lastName", "middleName",
                          "emailAddress", "emailPurposeTypeId",
                          "contactNumber", "areaCode", "countryCode",
                          "address1", "address2", "city", "postalCode",
                          "countryGeoId", "stateProvinceGeoId", "statusId", "createdDate")
                  .from("FindCustomerView")
                  .where(condition)
                  .queryList()

    // Deduplicate: view can produce multiple rows per party (phone + address joins)
    def seen = [] as Set
    def customerList = rawList.findAll { row -> seen.add(row.getString("partyId")) }

    return ServiceUtil.returnSuccess() + [customerList: customerList]
}

findCustomer()
