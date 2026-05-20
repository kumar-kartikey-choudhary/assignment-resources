import org.apache.ofbiz.entity.GenericValue

// 1. Fetch Person or Organization Name
GenericValue person = delegator.findOne("RmPerson", [partyId: partyId], true)
GenericValue organization = delegator.findOne("RmOrganization", [partyId: partyId], true)

if (person != null) {
    context.partyName = person.firstName + " " + (person.lastName ?: "")
} else if (organization != null) {
    context.partyName = organization.organizationName
} else {
    context.partyName = "N/A"
}

// 2. Fetch Assigned Roles
List<GenericValue> partyRoles = delegator.findByAnd("RmPartyRole", [partyId: partyId], null, true)
context.rolesList = partyRoles.collect { it.roleTypeId }.join(", ")

// 3. Fetch and format Contact Mechanisms
List<GenericValue> partyContactMechs = delegator.findByAnd("RmPartyContactMech", [partyId: partyId], null, true)
def contacts = []

partyContactMechs.each { pcm ->
    GenericValue cm = delegator.findOne("RmContactMech", [contactMechId: pcm.contactMechId], true)
    if (cm != null) {
        if (cm.contactMechTypeId == "EMAIL_ADDRESS" || cm.contactMechTypeId == "WEB_ADDRESS") {
            contacts.add(cm.infoString)
        } else if (cm.contactMechTypeId == "TELECOM_NUMBER") {
            GenericValue tn = delegator.findOne("RmTelecomNumber", [contactMechId: pcm.contactMechId], true)
            if (tn != null) {
                contacts.add("${tn.countryCode ?: ''}-${tn.areaCode ?: ''}-${tn.contactNumber ?: ''}")
            }
        } else if (cm.contactMechTypeId == "POSTAL_ADDRESS") {
            GenericValue pa = delegator.findOne("RmPostalAddress", [contactMechId: pcm.contactMechId], true)
            if (pa != null) {
                contacts.add("${pa.address1 ?: ''}, ${pa.city ?: ''}, ${pa.stateProvinceGeoId ?: ''}")
            }
        }
    }
}

context.contactsList = contacts ? contacts.join(" | ") : "None"