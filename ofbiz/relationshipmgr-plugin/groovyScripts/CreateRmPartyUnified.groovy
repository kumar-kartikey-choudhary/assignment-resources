import org.apache.ofbiz.entity.GenericValue
import org.apache.ofbiz.service.ServiceUtil

def createRmPartyUnified() {
    // 1. Prepare base party parameters
    Map createPartyCtx = [
        partyTypeId: parameters.partyTypeId
    ]
    if (parameters.partyId) {
        createPartyCtx.partyId = parameters.partyId
    }

    Map partyResult = run service: 'createRmParty', with: createPartyCtx
    if (ServiceUtil.isError(partyResult)) {
        return partyResult
    }
    String partyId = partyResult.partyId

    // 2. Based on partyTypeId, create subtype records
    if ("PERSON".equals(parameters.partyTypeId)) {
        Map personCtx = [
            partyId: partyId,
            firstName: parameters.firstName,
            lastName: parameters.lastName,
            birthDate: parameters.birthDate
        ]
        Map personResult = run service: 'createRmPerson', with: personCtx
        if (ServiceUtil.isError(personResult)) {
            return personResult
        }
    } else if ("ORGANIZATION".equals(parameters.partyTypeId)) {
        Map orgCtx = [
            partyId: partyId,
            organizationName: parameters.organizationName
        ]
        Map orgResult = run service: 'createRmOrganization', with: orgCtx
        if (ServiceUtil.isError(orgResult)) {
            return orgResult
        }
    }

    return success([partyId: partyId])
}
