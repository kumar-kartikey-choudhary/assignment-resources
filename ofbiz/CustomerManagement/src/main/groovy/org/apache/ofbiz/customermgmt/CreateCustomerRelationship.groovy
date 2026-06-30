/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.
 */
package org.apache.ofbiz.customermgmt

import org.apache.ofbiz.base.util.UtilDateTime
import org.apache.ofbiz.service.ServiceUtil

/**
 * createCustomerRelationship service
 *
 * Creates a PartyRelationship record linking partyIdFrom → partyIdTo.
 * Validates both parties exist and no duplicate active relationship of
 * the same type already exists.
 */
Map createCustomerRelationship() {
    def partyIdFrom             = parameters.partyIdFrom
    def partyIdTo               = parameters.partyIdTo
    def partyRelationshipTypeId = parameters.partyRelationshipTypeId
    def roleTypeIdFrom          = parameters.roleTypeIdFrom ?: "CUSTOMER"
    def roleTypeIdTo            = parameters.roleTypeIdTo   ?: "CUSTOMER"

    // Validate parties exist
    if (!delegator.findOne("Party", [partyId: partyIdFrom], false)) {
        return ServiceUtil.returnError("Party '${partyIdFrom}' not found.")
    }
    if (!delegator.findOne("Party", [partyId: partyIdTo], false)) {
        return ServiceUtil.returnError("Party '${partyIdTo}' not found.")
    }

    // Check for duplicate active relationship
    def existing = select("partyIdFrom","partyIdTo","partyRelationshipTypeId","fromDate","thruDate")
                   .from("PartyRelationship")
                   .where([partyIdFrom: partyIdFrom,
                           partyIdTo: partyIdTo,
                           partyRelationshipTypeId: partyRelationshipTypeId,
                           roleTypeIdFrom: roleTypeIdFrom,
                           roleTypeIdTo: roleTypeIdTo])
                   .filterByDate()
                   .queryFirst()
    if (existing) {
        return ServiceUtil.returnError(
            "Active '${partyRelationshipTypeId}' relationship already exists between '${partyIdFrom}' and '${partyIdTo}'.")
    }

    def now = UtilDateTime.nowTimestamp()
    def rel = delegator.makeValue("PartyRelationship")
    rel.set("partyIdFrom",             partyIdFrom)
    rel.set("partyIdTo",               partyIdTo)
    rel.set("partyRelationshipTypeId", partyRelationshipTypeId)
    rel.set("roleTypeIdFrom",          roleTypeIdFrom)
    rel.set("roleTypeIdTo",            roleTypeIdTo)
    rel.set("fromDate",                now)
    rel.set("statusId",                parameters.statusId ?: "PARTYREL_CREATED")
    delegator.create(rel)

    logInfo("Created PartyRelationship type=${partyRelationshipTypeId} from=${partyIdFrom} to=${partyIdTo}")
    return ServiceUtil.returnSuccess() + [fromDate: now]
}

createCustomerRelationship()
