package org.apache.ofbiz.productmgmt

import org.apache.ofbiz.entity.GenericValue
import org.apache.ofbiz.service.ServiceUtil
import org.apache.ofbiz.service.testtools.OFBizTestCase

class ProductManagementTests extends OFBizTestCase {

    ProductManagementTests(String name) {
        super(name)
    }

    void testProductFlow() {
        // Query system userLogin for service authentication
        GenericValue userLogin = from("UserLogin").where("userLoginId", "system").queryOne()
        assert userLogin != null

        // 1. Ensure required Seed/Type data exists to prevent FK constraint failures
        
        // ProductType FINISHED_GOOD
        if (!from("ProductType").where("productTypeId", "FINISHED_GOOD").queryOne()) {
            delegator.create(delegator.makeValue("ProductType", [
                productTypeId: "FINISHED_GOOD",
                isPhysical: "Y",
                isDigital: "N",
                hasTable: "N",
                description: "Finished Good"
            ]))
        }

        // ProductCategoryType CATALOG
        if (!from("ProductCategoryType").where("productCategoryTypeId", "CATALOG").queryOne()) {
            delegator.create(delegator.makeValue("ProductCategoryType", [
                productCategoryTypeId: "CATALOG",
                hasTable: "N",
                description: "Catalog Category Type"
            ]))
        }

        // ProductCategory TEST_CATALOG
        String categoryId = "TEST_CATALOG"
        if (!from("ProductCategory").where("productCategoryId", categoryId).queryOne()) {
            delegator.create(delegator.makeValue("ProductCategory", [
                productCategoryId: categoryId,
                productCategoryTypeId: "CATALOG",
                categoryName: "Test Category"
            ]))
        }

        // ProductPriceType LIST_PRICE
        if (!from("ProductPriceType").where("productPriceTypeId", "LIST_PRICE").queryOne()) {
            delegator.create(delegator.makeValue("ProductPriceType", [
                productPriceTypeId: "LIST_PRICE",
                description: "List Price"
            ]))
        }

        // ProductPricePurpose PURCHASE
        if (!from("ProductPricePurpose").where("productPricePurposeId", "PURCHASE").queryOne()) {
            delegator.create(delegator.makeValue("ProductPricePurpose", [
                productPricePurposeId: "PURCHASE",
                description: "Purchase Purpose"
            ]))
        }

        // ProductStoreGroupType
        if (!from("ProductStoreGroupType").where("productStoreGroupTypeId", "UNSPECIFIED").queryOne()) {
            delegator.create(delegator.makeValue("ProductStoreGroupType", [
                productStoreGroupTypeId: "UNSPECIFIED",
                description: "Unspecified Store Group Type"
            ]))
        }

        // ProductStoreGroup _NA_
        GenericValue existingNA = from("ProductStoreGroup").where("productStoreGroupId", "_NA_").queryOne()
        if (!existingNA) {
            delegator.create(delegator.makeValue("ProductStoreGroup", [
                productStoreGroupId: "_NA_",
                productStoreGroupTypeId: "UNSPECIFIED",
                description: "Not Applicable Group"
            ]))
        }

        // ProductAssocType PRODUCT_VARIANT
        if (!from("ProductAssocType").where("productAssocTypeId", "PRODUCT_VARIANT").queryOne()) {
            delegator.create(delegator.makeValue("ProductAssocType", [
                productAssocTypeId: "PRODUCT_VARIANT",
                description: "Product Variant Association"
            ]))
        }

        // UomType CURRENCY_MEASURE
        if (!from("UomType").where("uomTypeId", "CURRENCY_MEASURE").queryOne()) {
            delegator.create(delegator.makeValue("UomType", [
                uomTypeId: "CURRENCY_MEASURE",
                description: "Currency Measure"
            ]))
        }

        // Uom USD (Currency)
        if (!from("Uom").where("uomId", "USD").queryOne()) {
            delegator.create(delegator.makeValue("Uom", [
                uomId: "USD",
                uomTypeId: "CURRENCY_MEASURE",
                abbreviation: "USD",
                description: "United States Dollar"
            ]))
        }

        // 2. Perform Service flow testing

        // 1. Create product
        String uniqueName = "TestWidget-${System.currentTimeMillis()}"
        Map createCtx = [
            userLogin: userLogin,
            productName: uniqueName,
            productCategoryId: categoryId,
            price: 19.99,
            currencyUomId: "USD"
        ]
        Map createResult = dispatcher.runSync("createProduct", createCtx)
        assert ServiceUtil.isSuccess(createResult)
        String productId = createResult.productId
        assert productId != null

        // 2. Try to create duplicate product name (should fail/error)
        Map createDuplicateCtx = [
            userLogin: userLogin,
            productName: uniqueName,
            productCategoryId: categoryId,
            price: 9.99
        ]
        Map duplicateResult = dispatcher.runSync("createProduct", createDuplicateCtx)
        assert ServiceUtil.isError(duplicateResult)

        // 3. Find product by name filter
        Map findCtx = [
            userLogin: userLogin,
            productName: uniqueName
        ]
        Map findResult = dispatcher.runSync("findProduct", findCtx)
        assert ServiceUtil.isSuccess(findResult)
        List productList = findResult.productList
        assert productList != null
        assert productList.size() > 0
        assert productList.any { it.productId == productId }

        // 4. Update product price
        Map updateCtx = [
            userLogin: userLogin,
            productId: productId,
            price: 29.99,
            currencyUomId: "USD"
        ]
        Map updateResult = dispatcher.runSync("updateProduct", updateCtx)
        assert ServiceUtil.isSuccess(updateResult)

        // 5. Create virtual product to test association
        String virtualName = "VirtualWidget-${System.currentTimeMillis()}"
        Map createVirtualCtx = [
            userLogin: userLogin,
            productName: virtualName,
            productCategoryId: categoryId,
            price: 0.00
        ]
        Map createVirtualResult = dispatcher.runSync("createProduct", createVirtualCtx)
        assert ServiceUtil.isSuccess(createVirtualResult)
        String virtualProductId = createVirtualResult.productId
        assert virtualProductId != null

        // Set virtual property directly
        GenericValue virtualProductVal = from("Product").where("productId", virtualProductId).queryOne()
        virtualProductVal.set("isVirtual", "Y")
        virtualProductVal.store()

        // 6. Associate product to virtual
        Map assocCtx = [
            userLogin: userLogin,
            productId: productId,
            virtualProductId: virtualProductId
        ]
        Map assocResult = dispatcher.runSync("assocProductToVirtual", assocCtx)
        assert ServiceUtil.isSuccess(assocResult)
        def fromDate = assocResult.fromDate
        assert fromDate != null

        // 7. Update variant association
        Map updateAssocCtx = [
            userLogin: userLogin,
            productId: productId,
            virtualProductId: virtualProductId,
            fromDate: fromDate,
            reason: "Updated via test"
        ]
        Map updateAssocResult = dispatcher.runSync("updateProductVariant", updateAssocCtx)
        assert ServiceUtil.isSuccess(updateAssocResult)
    }
}
