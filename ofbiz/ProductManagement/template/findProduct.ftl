<#--
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
-->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Find Product | Product Management</title>
    <meta name="description" content="Search, create, and manage products in the OFBiz Product Management plugin."/>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        :root {
            --bg: #0f1117;
            --surface: #1a1d27;
            --surface2: #242836;
            --border: #2e3248;
            --accent: #6c63ff;
            --accent2: #4ecdc4;
            --text: #e8eaf0;
            --text-muted: #8b91a8;
            --success: #2ecc71;
            --error: #e74c3c;
            --radius: 12px;
        }
        body { font-family: 'Inter', sans-serif; background: var(--bg); color: var(--text); min-height: 100vh; }

        /* ---- Header ---- */
        .header {
            background: linear-gradient(135deg, #1a1d27 0%, #242836 100%);
            border-bottom: 1px solid var(--border);
            padding: 1.25rem 2rem;
            display: flex; align-items: center; gap: 1rem;
        }
        .header-logo { font-size: 1.5rem; font-weight: 700; background: linear-gradient(135deg,#6c63ff,#4ecdc4); -webkit-background-clip:text; -webkit-text-fill-color:transparent; }
        .header-sub { color: var(--text-muted); font-size: 0.85rem; }

        /* ---- Layout ---- */
        .container { max-width: 1280px; margin: 0 auto; padding: 2rem; }

        /* ---- Section cards ---- */
        .card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            padding: 1.5rem;
            margin-bottom: 1.5rem;
        }
        .card-title { font-size: 1rem; font-weight: 600; color: var(--accent2); margin-bottom: 1.2rem; display:flex; align-items:center; gap:.5rem; }

        /* ---- Flash messages ---- */
        .flash { padding: .75rem 1rem; border-radius: 8px; margin-bottom: 1rem; font-size: .9rem; }
        .flash-success { background: rgba(46,204,113,.15); border:1px solid var(--success); color: var(--success); }
        .flash-error   { background: rgba(231,76,60,.15);  border:1px solid var(--error);   color: var(--error);   }

        /* ---- Search form ---- */
        .form-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 1rem; }
        .form-group label { display: block; font-size: .8rem; color: var(--text-muted); margin-bottom: .4rem; }
        .form-group input, .form-group select {
            width: 100%; padding: .6rem .9rem;
            background: var(--surface2); border: 1px solid var(--border);
            border-radius: 8px; color: var(--text); font-family: inherit; font-size: .9rem;
            transition: border-color .2s;
        }
        .form-group input:focus, .form-group select:focus { outline: none; border-color: var(--accent); }

        /* ---- Buttons ---- */
        .btn { display:inline-flex; align-items:center; gap:.4rem; padding:.6rem 1.2rem; border-radius:8px; font-size:.875rem; font-weight:500; border:none; cursor:pointer; transition: transform .15s, box-shadow .15s; }
        .btn:hover { transform: translateY(-1px); box-shadow: 0 4px 12px rgba(0,0,0,.3); }
        .btn-primary { background: linear-gradient(135deg,#6c63ff,#5a54e8); color:#fff; }
        .btn-success { background: linear-gradient(135deg,#2ecc71,#27ae60); color:#fff; }
        .btn-warning { background: linear-gradient(135deg,#f39c12,#e67e22); color:#fff; }
        .btn-sm { padding:.4rem .8rem; font-size:.8rem; }
        .btn-row { display:flex; gap:.75rem; flex-wrap:wrap; margin-top:1rem; }

        /* ---- Results table ---- */
        .table-wrap { overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; font-size: .875rem; }
        thead th { background: var(--surface2); color: var(--text-muted); font-weight: 500; padding: .75rem 1rem; text-align:left; border-bottom: 1px solid var(--border); }
        tbody tr { border-bottom: 1px solid var(--border); transition: background .15s; }
        tbody tr:hover { background: rgba(108,99,255,.06); }
        tbody td { padding: .7rem 1rem; vertical-align: middle; }
        .badge { display:inline-block; padding:.2rem .55rem; border-radius:20px; font-size:.75rem; font-weight:500; }
        .badge-virtual { background:rgba(108,99,255,.2); color:#6c63ff; }
        .badge-variant { background:rgba(78,205,196,.2); color:#4ecdc4; }

        /* ---- Pagination ---- */
        .pagination { display:flex; justify-content:center; gap:.5rem; margin-top:1.5rem; flex-wrap:wrap; }
        .page-btn { padding:.4rem .85rem; border-radius:6px; background:var(--surface2); border:1px solid var(--border); color:var(--text); cursor:pointer; font-size:.85rem; transition:background .15s; }
        .page-btn:hover, .page-btn.active { background:var(--accent); border-color:var(--accent); color:#fff; }

        /* ---- Create / Update collapsibles ---- */
        details summary { cursor:pointer; user-select:none; list-style:none; }
        details summary::-webkit-details-marker { display:none; }
        details[open] summary .chevron { transform: rotate(180deg); }
        .chevron { display:inline-block; transition: transform .2s; margin-left:.5rem; }
        .create-grid { display:grid; grid-template-columns: repeat(auto-fill, minmax(220px,1fr)); gap:1rem; margin-top:1rem; }
    </style>
</head>
<body>

<#-- ---- Retrieve context variables set by Groovy/Service ---- -->
<#assign parameters = requestParameters!{}>
<#assign productList  = (productList![])>
<#assign errorMessage = (errorMessage!"")>
<#assign successMessage = (successMessage!"")>

<#-- Pagination settings -->
<#assign pageSize = 10>
<#assign currentPage = (parameters.page?has_content)?then(parameters.page?number, 1)>
<#assign totalCount  = productList?size>
<#assign totalPages  = (totalCount > 0)?then(((totalCount - 1) / pageSize)?int + 1, 1)>
<#assign startIdx    = (currentPage - 1) * pageSize>
<#assign endIdx      = [startIdx + pageSize, totalCount]?min>
<#assign pageProducts = (totalCount > 0)?then(productList[startIdx..endIdx - 1]![], [])>

<header class="header">
    <span class="header-logo">&#9881; ProductManagement</span>
    <span class="header-sub">/ Find Product</span>
</header>

<div class="container">

    <#-- Flash messages -->
    <#if errorMessage?has_content>
        <div class="flash flash-error">&#9888; ${errorMessage}</div>
    </#if>
    <#if successMessage?has_content>
        <div class="flash flash-success">&#10003; ${successMessage}</div>
    </#if>

    <!-- ===== Search Form ===== -->
    <div class="card">
        <div class="card-title">&#128269; Search Products</div>
        <form id="findProductForm" method="post" action="<@ofbizUrl>FindProduct</@ofbizUrl>">
            <input type="hidden" name="page" value="1"/>
            <div class="form-grid">
                <div class="form-group">
                    <label for="productId">Product ID</label>
                    <input type="text" id="productId" name="productId" placeholder="Partial match..." value="${parameters.productId!}"/>
                </div>
                <div class="form-group">
                    <label for="productName">Product Name</label>
                    <input type="text" id="productName" name="productName" placeholder="Partial match..." value="${parameters.productName!}"/>
                </div>
                <div class="form-group">
                    <label for="productCategoryId">Category ID</label>
                    <input type="text" id="productCategoryId" name="productCategoryId" placeholder="e.g. CATALOG" value="${parameters.productCategoryId!}"/>
                </div>
                <div class="form-group">
                    <label for="minPrice">Min Price</label>
                    <input type="number" id="minPrice" name="minPrice" step="0.01" placeholder="0.00" value="${parameters.minPrice!}"/>
                </div>
                <div class="form-group">
                    <label for="maxPrice">Max Price</label>
                    <input type="number" id="maxPrice" name="maxPrice" step="0.01" placeholder="9999.99" value="${parameters.maxPrice!}"/>
                </div>
                <div class="form-group">
                    <label for="productFeatureTypeId">Feature Type</label>
                    <input type="text" id="productFeatureTypeId" name="productFeatureTypeId" placeholder="e.g. COLOR, SIZE" value="${parameters.productFeatureTypeId!}"/>
                </div>
                <div class="form-group">
                    <label for="productFeatureId">Feature ID</label>
                    <input type="text" id="productFeatureId" name="productFeatureId" placeholder="Feature ID" value="${parameters.productFeatureId!}"/>
                </div>
            </div>
            <div class="btn-row">
                <button type="submit" class="btn btn-primary">&#128269; Search</button>
                <a href="<@ofbizUrl>FindProduct</@ofbizUrl>" class="btn" style="background:var(--surface2);color:var(--text-muted);border:1px solid var(--border);">&#10006; Clear</a>
            </div>
        </form>
    </div>

    <!-- ===== Create Product ===== -->
    <div class="card">
        <details>
            <summary>
                <div class="card-title" style="cursor:pointer; margin-bottom:0;">
                    &#43; Create New Product
                    <span class="chevron">&#8964;</span>
                </div>
            </summary>
            <form method="post" action="<@ofbizUrl>createProduct</@ofbizUrl>" style="margin-top:1rem;">
                <div class="create-grid">
                    <div class="form-group">
                        <label for="cp_productName">Product Name *</label>
                        <input type="text" id="cp_productName" name="productName" required placeholder="Unique product name"/>
                    </div>
                    <div class="form-group">
                        <label for="cp_productCategoryId">Category ID *</label>
                        <input type="text" id="cp_productCategoryId" name="productCategoryId" required placeholder="e.g. CATALOG"/>
                    </div>
                    <div class="form-group">
                        <label for="cp_price">List Price *</label>
                        <input type="number" id="cp_price" name="price" step="0.01" required placeholder="0.00"/>
                    </div>
                    <div class="form-group">
                        <label for="cp_currencyUomId">Currency</label>
                        <input type="text" id="cp_currencyUomId" name="currencyUomId" value="USD" placeholder="USD"/>
                    </div>
                    <div class="form-group">
                        <label for="cp_internalName">Internal Name</label>
                        <input type="text" id="cp_internalName" name="internalName" placeholder="Internal name"/>
                    </div>
                    <div class="form-group">
                        <label for="cp_brandName">Brand Name</label>
                        <input type="text" id="cp_brandName" name="brandName" placeholder="Brand"/>
                    </div>
                    <div class="form-group">
                        <label for="cp_description">Description</label>
                        <input type="text" id="cp_description" name="description" placeholder="Short description"/>
                    </div>
                    <div class="form-group">
                        <label for="cp_productTypeId">Product Type</label>
                        <input type="text" id="cp_productTypeId" name="productTypeId" value="FINISHED_GOOD" placeholder="FINISHED_GOOD"/>
                    </div>
                </div>
                <div class="btn-row">
                    <button type="submit" class="btn btn-success">&#43; Create Product</button>
                </div>
            </form>
        </details>
    </div>

    <!-- ===== Update Product ===== -->
    <div class="card">
        <details>
            <summary>
                <div class="card-title" style="cursor:pointer; margin-bottom:0;">
                    &#9998; Update Product
                    <span class="chevron">&#8964;</span>
                </div>
            </summary>
            <form method="post" action="<@ofbizUrl>updateProduct</@ofbizUrl>" style="margin-top:1rem;">
                <div class="create-grid">
                    <div class="form-group">
                        <label for="up_productId">Product ID *</label>
                        <input type="text" id="up_productId" name="productId" required placeholder="e.g. 10000"/>
                    </div>
                    <div class="form-group">
                        <label for="up_productName">New Product Name</label>
                        <input type="text" id="up_productName" name="productName" placeholder="Leave blank to keep"/>
                    </div>
                    <div class="form-group">
                        <label for="up_price">New Price</label>
                        <input type="number" id="up_price" name="price" step="0.01" placeholder="Leave blank to keep"/>
                    </div>
                    <div class="form-group">
                        <label for="up_currencyUomId">Currency</label>
                        <input type="text" id="up_currencyUomId" name="currencyUomId" placeholder="USD"/>
                    </div>
                    <div class="form-group">
                        <label for="up_productFeatureId">Feature ID</label>
                        <input type="text" id="up_productFeatureId" name="productFeatureId" placeholder="e.g. RED"/>
                    </div>
                    <div class="form-group">
                        <label for="up_featureApplTypeId">Feature Appl Type</label>
                        <input type="text" id="up_featureApplTypeId" name="productFeatureApplTypeId" value="STANDARD_FEATURE" placeholder="STANDARD_FEATURE"/>
                    </div>
                    <div class="form-group">
                        <label for="up_description">Description</label>
                        <input type="text" id="up_description" name="description" placeholder="Leave blank to keep"/>
                    </div>
                </div>
                <div class="btn-row">
                    <button type="submit" class="btn btn-warning">&#9998; Update Product</button>
                </div>
            </form>
        </details>
    </div>

    <!-- ===== Virtual/Variant Association ===== -->
    <div class="card">
        <details>
            <summary>
                <div class="card-title" style="cursor:pointer; margin-bottom:0;">
                    &#128257; Virtual &amp; Variant Relationships
                    <span class="chevron">&#8964;</span>
                </div>
            </summary>
            <div style="display:grid; grid-template-columns:1fr 1fr; gap:1.5rem; margin-top:1rem;">
                <!-- Associate -->
                <form method="post" action="<@ofbizUrl>assocProductToVirtual</@ofbizUrl>">
                    <p style="font-size:.85rem;color:var(--text-muted);margin-bottom:.75rem;">&#9679; Assign variant to virtual product</p>
                    <div class="form-group" style="margin-bottom:.75rem;">
                        <label>Variant Product ID *</label>
                        <input type="text" name="productId" required placeholder="Variant product ID"/>
                    </div>
                    <div class="form-group" style="margin-bottom:.75rem;">
                        <label>Virtual Product ID *</label>
                        <input type="text" name="virtualProductId" required placeholder="Virtual product ID"/>
                    </div>
                    <button type="submit" class="btn btn-primary btn-sm">Assign Variant</button>
                </form>
                <!-- Update Association -->
                <form method="post" action="<@ofbizUrl>updateProductVariant</@ofbizUrl>">
                    <p style="font-size:.85rem;color:var(--text-muted);margin-bottom:.75rem;">&#9679; Update existing variant association</p>
                    <div class="form-group" style="margin-bottom:.75rem;">
                        <label>Variant Product ID *</label>
                        <input type="text" name="productId" required placeholder="Variant product ID"/>
                    </div>
                    <div class="form-group" style="margin-bottom:.75rem;">
                        <label>Virtual Product ID *</label>
                        <input type="text" name="virtualProductId" required placeholder="Virtual product ID"/>
                    </div>
                    <div class="form-group" style="margin-bottom:.75rem;">
                        <label>From Date (assoc) *</label>
                        <input type="datetime-local" name="fromDate" required/>
                    </div>
                    <div class="form-group" style="margin-bottom:.75rem;">
                        <label>Reason</label>
                        <input type="text" name="reason" placeholder="Optional reason"/>
                    </div>
                    <button type="submit" class="btn btn-warning btn-sm">Update Association</button>
                </form>
            </div>
        </details>
    </div>

    <!-- ===== Search Results Table ===== -->
    <div class="card">
        <div class="card-title">
            &#128202; Results
            <span style="font-size:.8rem;color:var(--text-muted);font-weight:400;margin-left:.5rem;">(${totalCount} product${(totalCount != 1)?then("s","")}) — Page ${currentPage} of ${totalPages}</span>
        </div>

        <#if pageProducts?has_content>
        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Product ID</th>
                        <th>Product Name</th>
                        <th>Category</th>
                        <th>Price</th>
                        <th>Currency</th>
                        <th>Feature ID</th>
                        <th>Feature Type</th>
                        <th>Type</th>
                    </tr>
                </thead>
                <tbody>
                    <#list pageProducts as p>
                    <tr>
                        <td><strong>${p.productId!"-"}</strong></td>
                        <td>${p.productName!p.internalName!"-"}</td>
                        <td>${p.productCategoryId!"-"}</td>
                        <td>${p.price?string("0.00")!"—"}</td>
                        <td>${p.currencyUomId!"-"}</td>
                        <td>${p.productFeatureId!"-"}</td>
                        <td>${p.productFeatureTypeId!"-"}</td>
                        <td>
                            <#if p.isVirtual?? && p.isVirtual == "Y">
                                <span class="badge badge-virtual">Virtual</span>
                            <#elseif p.isVariant?? && p.isVariant == "Y">
                                <span class="badge badge-variant">Variant</span>
                            <#else>
                                <span style="color:var(--text-muted);font-size:.8rem;">Standard</span>
                            </#if>
                        </td>
                    </tr>
                    </#list>
                </tbody>
            </table>
        </div>

        <!-- Pagination -->
        <#if totalPages gt 1>
        <div class="pagination">
            <#list 1..totalPages as pg>
                <a href="<@ofbizUrl>FindProduct?productId=${parameters.productId!}&amp;productName=${parameters.productName!}&amp;page=${pg}</@ofbizUrl>"
                   class="page-btn <#if pg == currentPage>active</#if>">${pg}</a>
            </#list>
        </div>
        </#if>

        <#else>
        <p style="color:var(--text-muted);text-align:center;padding:2rem 0;">No products found. Try adjusting your filters or create a new product above.</p>
        </#if>
    </div>

</div><!-- /container -->
</body>
</html>
