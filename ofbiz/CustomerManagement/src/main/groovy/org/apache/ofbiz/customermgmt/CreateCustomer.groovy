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
import org.apache.ofbiz.service.ServiceUtil

/**
 * createCustomer service
 *
 * 1. Calls findCustomer with emailAddress — errors if customer already exists (email uniqueness).
 * 2. Creates Party (partyTypeId=PERSON).
 * 3. Creates Person (firstName, lastName…).
 * 4. Creates PartyRole (CUSTOMER).
 * 5. Creates ContactMech (EMAIL_ADDRESS) + PartyContactMech + PartyContactMechPurpose(PRIMARY_EMAIL).
 * 6. Optionally creates TelecomNumber ContactMech + PartyContactMechPurpose(PRIMARY_PHONE).
 * 7. Optionally creates PostalAddress ContactMech + PartyContactMechPurpose(PRIMARY_LOCATION).
 */
Map createCustomer() {
    def emailAddress  = parameters.emailAddress?.trim()
    def firstName     = parameters.firstName
    def lastName      = parameters.lastName

    // --- 1. Uniqueness check ---
    def findResult = runService("findCustomer", [emailAddress: emailAddress])
    if (ServiceUtil.isError(findResult)) return findResult
    if (findResult.customerList) {
        return ServiceUtil.returnError(
            "A customer with email '${emailAddress}' already exists. Email addresses must be unique.")
    }

    def now     = UtilDateTime.nowTimestamp()
    def loginId = userLogin?.getString("userLoginId")

    // --- 2. Create Party ---
    def partyId = delegator.getNextSeqId("Party")
    def party   = delegator.makeValue("Party")
    party.set("partyId",                 partyId)
    party.set("partyTypeId",             "PERSON")
    party.set("statusId",                "PARTY_ENABLED")
    party.set("createdDate",             now)
    party.set("lastModifiedDate",        now)
    party.set("createdByUserLogin",      loginId)
    party.set("lastModifiedByUserLogin", loginId)
    delegator.create(party)

    // --- 3. Create Person ---
    def person = delegator.makeValue("Person")
    person.set("partyId",     partyId)
    person.set("firstName",   firstName)
    person.set("lastName",    lastName)
    person.set("middleName",  parameters.middleName)
    person.set("salutation",  parameters.salutation)
    delegator.create(person)

    // --- 4. Create PartyRole (CUSTOMER) ---
    try {
        def partyRole = delegator.makeValue("PartyRole")
        partyRole.set("partyId",     partyId)
        partyRole.set("roleTypeId",  "CUSTOMER")
        delegator.create(partyRole)
    } catch (Exception e) {
        logWarning("Could not create PartyRole CUSTOMER for partyId=${partyId}: ${e.message}")
    }

    // --- 5. Create Email ContactMech ---
    def emailCmId = delegator.getNextSeqId("ContactMech")
    def emailCm   = delegator.makeValue("ContactMech")
    emailCm.set("contactMechId",     emailCmId)
    emailCm.set("contactMechTypeId", "EMAIL_ADDRESS")
    emailCm.set("infoString",        emailAddress)
    delegator.create(emailCm)

    // PartyContactMech for email
    def emailPcm = delegator.makeValue("PartyContactMech")
    emailPcm.set("partyId",        partyId)
    emailPcm.set("contactMechId",  emailCmId)
    emailPcm.set("fromDate",       now)
    delegator.create(emailPcm)

    // PartyContactMechPurpose PRIMARY_EMAIL
    def emailPcmp = delegator.makeValue("PartyContactMechPurpose")
    emailPcmp.set("partyId",                  partyId)
    emailPcmp.set("contactMechId",            emailCmId)
    emailPcmp.set("contactMechPurposeTypeId", "PRIMARY_EMAIL")
    emailPcmp.set("fromDate",                 now)
    delegator.create(emailPcmp)

    // --- 6. Create TelecomNumber (optional) ---
    def contactNumber = parameters.contactNumber
    if (contactNumber) {
        def phoneCmId = delegator.getNextSeqId("ContactMech")
        def phoneCm   = delegator.makeValue("ContactMech")
        phoneCm.set("contactMechId",     phoneCmId)
        phoneCm.set("contactMechTypeId", "TELECOM_NUMBER")
        delegator.create(phoneCm)

        def telecom = delegator.makeValue("TelecomNumber")
        telecom.set("contactMechId",  phoneCmId)
        telecom.set("countryCode",    parameters.countryCode ?: "1")
        telecom.set("areaCode",       parameters.areaCode)
        telecom.set("contactNumber",  contactNumber)
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

    // --- 7. Create PostalAddress (optional) ---
    def address1 = parameters.address1
    if (address1) {
        def addrCmId = delegator.getNextSeqId("ContactMech")
        def addrCm   = delegator.makeValue("ContactMech")
        addrCm.set("contactMechId",     addrCmId)
        addrCm.set("contactMechTypeId", "POSTAL_ADDRESS")
        delegator.create(addrCm)

        def postalAddr = delegator.makeValue("PostalAddress")
        postalAddr.set("contactMechId",   addrCmId)
        postalAddr.set("address1",        address1)
        postalAddr.set("address2",        parameters.address2)
        postalAddr.set("city",            parameters.city)
        postalAddr.set("postalCode",      parameters.postalCode)
        postalAddr.set("countryGeoId",    parameters.countryGeoId ?: "USA")
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

    logInfo("Created customer partyId=${partyId} email='${emailAddress}'")
    return ServiceUtil.returnSuccess() + [partyId: partyId]
}

createCustomer()
