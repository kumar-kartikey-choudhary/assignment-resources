/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.
 */
package org.apache.ofbiz.customermgmt

import org.apache.ofbiz.service.ServiceUtil

/**
 * updateCustomerRelationship service
 *
 * Updates statusId, thruDate, or comments on an existing PartyRelationship
 * identified by composite PK (partyIdFrom, partyIdTo, partyRelationshipTypeId,
 * roleTypeIdFrom, roleTypeIdTo, fromDate).
 */
Map updateCustomerRelationship() {
    def partyIdFrom             = parameters.partyIdFrom
    def partyIdTo               = parameters.partyIdTo
    def partyRelationshipTypeId = parameters.partyRelationshipTypeId
    def roleTypeIdFrom          = parameters.roleTypeIdFrom
    def roleTypeIdTo            = parameters.roleTypeIdTo
    def fromDate                = parameters.fromDate

    def rel = delegator.findOne("PartyRelationship",
        [partyIdFrom: partyIdFrom,
         partyIdTo: partyIdTo,
         roleTypeIdFrom: roleTypeIdFrom,
         roleTypeIdTo: roleTypeIdTo,
         fromDate: fromDate], false)

    if (!rel) {
        return ServiceUtil.returnError(
            "No PartyRelationship found from '${partyIdFrom}' to '${partyIdTo}' " +
            "type '${partyRelationshipTypeId}' fromDate '${fromDate}'.")
    }

    def changed = false
    if (parameters.statusId)  { rel.set("statusId",  parameters.statusId);  changed = true }
    if (parameters.thruDate)  { rel.set("thruDate",  parameters.thruDate);  changed = true }
    if (parameters.comments)  { rel.set("comments",  parameters.comments);  changed = true }

    if (changed) {
        rel.store()
        logInfo("Updated PartyRelationship from=${partyIdFrom} to=${partyIdTo}")
    }
    return ServiceUtil.returnSuccess()
}

updateCustomerRelationship()
