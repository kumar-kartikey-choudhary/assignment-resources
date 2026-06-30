package org.apache.ofbiz.customermgmt

import org.apache.ofbiz.entity.GenericValue
import org.apache.ofbiz.service.ServiceUtil
import org.apache.ofbiz.service.testtools.OFBizTestCase

class CustomerManagementTests extends OFBizTestCase {

    CustomerManagementTests(String name) {
        super(name)
    }

    void testCustomerFlow() {
        // Query system userLogin for service authentication
        GenericValue userLogin = from("UserLogin").where("userLoginId", "system").queryOne()
        assert userLogin != null

        // 1. Create a customer
        String uniqueEmail = "testcustomer-${System.currentTimeMillis()}@example.com"
        Map createCtx = [
            userLogin: userLogin,
            emailAddress: uniqueEmail,
            firstName: "Alice",
            lastName: "Smith",
            contactNumber: "555-9876",
            address1: "100 Test Lane",
            city: "Springfield",
            postalCode: "62701"
        ]
        Map createResult = dispatcher.runSync("createCustomer", createCtx)
        assert ServiceUtil.isSuccess(createResult)
        String partyId = createResult.partyId
        assert partyId != null

        // 2. Try to create duplicate customer (should fail/error)
        Map createDuplicateCtx = [
            userLogin: userLogin,
            emailAddress: uniqueEmail,
            firstName: "Bob",
            lastName: "Jones"
        ]
        Map duplicateResult = dispatcher.runSync("createCustomer", createDuplicateCtx)
        assert ServiceUtil.isError(duplicateResult)

        // 3. Find customer by email filter
        Map findCtx = [
            userLogin: userLogin,
            emailAddress: uniqueEmail
        ]
        Map findResult = dispatcher.runSync("findCustomer", findCtx)
        assert ServiceUtil.isSuccess(findResult)
        List customerList = findResult.customerList
        assert customerList != null
        assert customerList.size() > 0
        assert customerList.any { it.partyId == partyId }

        // 4. Update customer phone and address
        Map updateCtx = [
            userLogin: userLogin,
            emailAddress: uniqueEmail,
            contactNumber: "555-0000",
            areaCode: "312",
            address1: "200 New Street",
            city: "Chicago",
            postalCode: "60601"
        ]
        Map updateResult = dispatcher.runSync("updateCustomer", updateCtx)
        assert ServiceUtil.isSuccess(updateResult)

        // 5. Create another customer to link with relationship
        String anotherEmail = "another-${System.currentTimeMillis()}@example.com"
        Map createAnotherCtx = [
            userLogin: userLogin,
            emailAddress: anotherEmail,
            firstName: "Bob",
            lastName: "Jones"
        ]
        Map anotherResult = dispatcher.runSync("createCustomer", createAnotherCtx)
        assert ServiceUtil.isSuccess(anotherResult)
        String anotherPartyId = anotherResult.partyId
        assert anotherPartyId != null

        // 6. Create relationship
        Map relCtx = [
            userLogin: userLogin,
            partyIdFrom: partyId,
            partyIdTo: anotherPartyId,
            partyRelationshipTypeId: "EMPLOYMENT"
        ]
        Map relResult = dispatcher.runSync("createCustomerRelationship", relCtx)
        assert ServiceUtil.isSuccess(relResult)
        def fromDate = relResult.fromDate
        assert fromDate != null

        // 7. Update relationship
        Map updateRelCtx = [
            userLogin: userLogin,
            partyIdFrom: partyId,
            partyIdTo: anotherPartyId,
            partyRelationshipTypeId: "EMPLOYMENT",
            roleTypeIdFrom: "CUSTOMER",
            roleTypeIdTo: "CUSTOMER",
            fromDate: fromDate,
            statusId: "PARTYREL_CREATED",
            comments: "Updated via test suite"
        ]
        Map updateRelResult = dispatcher.runSync("updateCustomerRelationship", updateRelCtx)
        assert ServiceUtil.isSuccess(updateRelResult)
    }
}
