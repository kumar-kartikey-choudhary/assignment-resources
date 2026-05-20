import org.apache.ofbiz.entity.GenericValue

// 1. Fetch RmContactMech
GenericValue cm = delegator.findOne("RmContactMech", [contactMechId: contactMechId], true)
if (cm != null) {
    context.contactMechTypeId = cm.contactMechTypeId
    if (cm.contactMechTypeId == "EMAIL_ADDRESS" || cm.contactMechTypeId == "WEB_ADDRESS") {
        context.contactMechDetail = cm.infoString ?: "N/A"
    } else if (cm.contactMechTypeId == "TELECOM_NUMBER") {
        GenericValue tn = delegator.findOne("RmTelecomNumber", [contactMechId: contactMechId], true)
        if (tn != null) {
            context.contactMechDetail = "${tn.countryCode ?: ''}-${tn.areaCode ?: ''}-${tn.contactNumber ?: ''}"
        } else {
            context.contactMechDetail = "N/A"
        }
    } else if (cm.contactMechTypeId == "POSTAL_ADDRESS") {
        GenericValue pa = delegator.findOne("RmPostalAddress", [contactMechId: contactMechId], true)
        if (pa != null) {
            context.contactMechDetail = "${pa.address1 ?: ''}, ${pa.city ?: ''}, ${pa.stateProvinceGeoId ?: ''}"
        } else {
            context.contactMechDetail = "N/A"
        }
    } else {
        context.contactMechDetail = cm.infoString ?: "N/A"
    }
} else {
    context.contactMechTypeId = "N/A"
    context.contactMechDetail = "N/A"
}

// 2. Fetch party name
GenericValue person = delegator.findOne("RmPerson", [partyId: partyId], true)
GenericValue organization = delegator.findOne("RmOrganization", [partyId: partyId], true)
if (person != null) {
    context.partyName = person.firstName + " " + (person.lastName ?: "")
} else if (organization != null) {
    context.partyName = organization.organizationName
} else {
    context.partyName = "N/A"
}
