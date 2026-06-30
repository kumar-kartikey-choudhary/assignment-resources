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

import org.apache.ofbiz.base.util.UtilDateTime
import org.apache.ofbiz.entity.condition.EntityCondition
import org.apache.ofbiz.entity.condition.EntityOperator
import org.apache.ofbiz.service.ServiceUtil

/**
 * updateCustomer service
 *
 * Identifies the customer by their PRIMARY_EMAIL address.
 * 1. Calls findCustomer(emailAddress) — errors if not found.
 * 2. Optionally updates Person (firstName, lastName).
 * 3. Optionally updates phone (TelecomNumber) — creates new if none exists.
 * 4. Optionally updates postal address (PostalAddress) — creates new if none exists.
 */
Map updateCustomer() {
    def emailAddress = parameters.emailAddress?.trim()

    // --- 1. Locate customer ---
    def findResult = runService("findCustomer", [emailAddress: emailAddress])
    if (ServiceUtil.isError(findResult)) return findResult
    if (!findResult.customerList) {
        return ServiceUtil.returnError("No customer found with email '${emailAddress}'.")
    }
    def customer = findResult.customerList[0]
    def partyId  = customer.getString("partyId")
    def now      = UtilDateTime.nowTimestamp()
    def loginId  = userLogin?.getString("userLoginId")

    // --- 2. Update Person name fields ---
    def newFirst = parameters.firstName
    def newLast  = parameters.lastName
    if (newFirst || newLast) {
        def person = delegator.findOne("Person", [partyId: partyId], false)
        if (person) {
            if (newFirst) person.set("firstName", newFirst)
            if (newLast)  person.set("lastName",  newLast)
            person.store()
        }
        // Update Party lastModifiedDate
        def party = delegator.findOne("Party", [partyId: partyId], false)
        if (party) {
            party.set("lastModifiedDate",        now)
            party.set("lastModifiedByUserLogin", loginId)
            party.store()
        }
    }

    // --- 3. Update / create phone ---
    def newContactNumber = parameters.contactNumber
    if (newContactNumber) {
        // Find an existing active PRIMARY_PHONE contact mech
        def phonePurposes = select("partyId","contactMechId","contactMechPurposeTypeId","fromDate","thruDate")
                            .from("PartyContactMechPurpose")
                            .where([partyId: partyId, contactMechPurposeTypeId: "PRIMARY_PHONE"])
                            .filterByDate()
                            .queryList()

        if (phonePurposes) {
            // Update the existing TelecomNumber
            def cmId    = phonePurposes[0].getString("contactMechId")
            def telecom = delegator.findOne("TelecomNumber", [contactMechId: cmId], false)
            if (telecom) {
                telecom.set("contactNumber", newContactNumber)
                if (parameters.areaCode)    telecom.set("areaCode",    parameters.areaCode)
                if (parameters.countryCode) telecom.set("countryCode", parameters.countryCode)
                telecom.store()
            }
        } else {
            // Create a new phone ContactMech
            def phoneCmId = delegator.getNextSeqId("ContactMech")
            def phoneCm   = delegator.makeValue("ContactMech")
            phoneCm.set("contactMechId",     phoneCmId)
            phoneCm.set("contactMechTypeId", "TELECOM_NUMBER")
            delegator.create(phoneCm)

            def telecom = delegator.makeValue("TelecomNumber")
            telecom.set("contactMechId",  phoneCmId)
            telecom.set("countryCode",    parameters.countryCode ?: "1")
            telecom.set("areaCode",       parameters.areaCode)
            telecom.set("contactNumber",  newContactNumber)
            delegator.create(telecom)

            def phonePcm = delegator.makeValue("PartyContactMech")
            phonePcm.set("partyId",       partyId)
            phonePcm.set("contactMechId", phoneCmId)
            phonePcm.set("fromDate",      now)
            delegator.create(phonePcm)

            def phonePcmp = delegator.makeValue("PartyContactMechPurpose")
            phonePcmp.set("partyId",                  partyId)
            phonePcmp.set("contactMechId",            phoneCmId)
            phonePcmp.set("contactMechPurposeTypeId", "PRIMARY_PHONE")
            phonePcmp.set("fromDate",                 now)
            delegator.create(phonePcmp)
        }
    }

    // --- 4. Update / create postal address ---
    def newAddress1 = parameters.address1
    if (newAddress1) {
        def addrPurposes = select("partyId","contactMechId","contactMechPurposeTypeId","fromDate","thruDate")
                           .from("PartyContactMechPurpose")
                           .where([partyId: partyId, contactMechPurposeTypeId: "PRIMARY_LOCATION"])
                           .filterByDate()
                           .queryList()

        if (addrPurposes) {
            def cmId   = addrPurposes[0].getString("contactMechId")
            def postal = delegator.findOne("PostalAddress", [contactMechId: cmId], false)
            if (postal) {
                postal.set("address1",     newAddress1)
                if (parameters.address2)    postal.set("address2",     parameters.address2)
                if (parameters.city)        postal.set("city",         parameters.city)
                if (parameters.postalCode)  postal.set("postalCode",   parameters.postalCode)
                if (parameters.countryGeoId) postal.set("countryGeoId", parameters.countryGeoId)
                postal.store()
            }
        } else {
            def addrCmId = delegator.getNextSeqId("ContactMech")
            def addrCm   = delegator.makeValue("ContactMech")
            addrCm.set("contactMechId",     addrCmId)
            addrCm.set("contactMechTypeId", "POSTAL_ADDRESS")
            delegator.create(addrCm)

            def postalAddr = delegator.makeValue("PostalAddress")
            postalAddr.set("contactMechId",  addrCmId)
            postalAddr.set("address1",       newAddress1)
            postalAddr.set("address2",       parameters.address2)
            postalAddr.set("city",           parameters.city)
            postalAddr.set("postalCode",     parameters.postalCode)
            postalAddr.set("countryGeoId",   parameters.countryGeoId ?: "USA")
            delegator.create(postalAddr)

            def addrPcm = delegator.makeValue("PartyContactMech")
            addrPcm.set("partyId",       partyId)
            addrPcm.set("contactMechId", addrCmId)
            addrPcm.set("fromDate",      now)
            delegator.create(addrPcm)

            def addrPcmp = delegator.makeValue("PartyContactMechPurpose")
            addrPcmp.set("partyId",                  partyId)
            addrPcmp.set("contactMechId",            addrCmId)
            addrPcmp.set("contactMechPurposeTypeId", "PRIMARY_LOCATION")
            addrPcmp.set("fromDate",                 now)
            delegator.create(addrPcmp)
        }
    }

    logInfo("Updated customer partyId=${partyId} via email='${emailAddress}'")
    return ServiceUtil.returnSuccess()
}

updateCustomer()
