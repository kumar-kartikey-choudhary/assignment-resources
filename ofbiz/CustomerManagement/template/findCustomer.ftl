<#--
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements. See the NOTICE file
for details. Apache License, Version 2.0.
-->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Find Customer | Customer Management</title>
    <meta name="description" content="Search, create, and manage customers in the OFBiz Customer Management plugin."/>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        :root {
            --bg: #0d1117; --surface: #161b22; --surface2: #21262d;
            --border: #30363d; --accent: #58a6ff; --accent2: #3fb950;
            --text: #e6edf3; --muted: #7d8590; --error: #f85149; --warn: #d29922;
            --radius: 10px;
        }
        body { font-family:'Inter',sans-serif; background:var(--bg); color:var(--text); min-height:100vh; }

        .header { background:var(--surface); border-bottom:1px solid var(--border); padding:1rem 2rem; display:flex; align-items:center; gap:1rem; }
        .logo { font-size:1.4rem; font-weight:700; background:linear-gradient(135deg,#58a6ff,#3fb950); -webkit-background-clip:text; -webkit-text-fill-color:transparent; }
        .logo-sub { color:var(--muted); font-size:.85rem; }

        .container { max-width:1300px; margin:0 auto; padding:1.75rem 2rem; }

        .card { background:var(--surface); border:1px solid var(--border); border-radius:var(--radius); padding:1.5rem; margin-bottom:1.5rem; }
        .card-title { font-size:.95rem; font-weight:600; color:var(--accent2); margin-bottom:1.2rem; display:flex; align-items:center; gap:.5rem; }

        .flash { padding:.7rem 1rem; border-radius:8px; margin-bottom:1rem; font-size:.875rem; }
        .flash-error   { background:rgba(248,81,73,.12);  border:1px solid var(--error);  color:var(--error); }
        .flash-success { background:rgba(63,185,80,.12);  border:1px solid var(--accent2); color:var(--accent2); }

        .form-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(190px,1fr)); gap:1rem; }
        label { display:block; font-size:.78rem; color:var(--muted); margin-bottom:.35rem; }
        input, select { width:100%; padding:.55rem .85rem; background:var(--surface2); border:1px solid var(--border); border-radius:7px; color:var(--text); font-family:inherit; font-size:.875rem; transition:border-color .2s; }
        input:focus, select:focus { outline:none; border-color:var(--accent); }

        .btn { display:inline-flex; align-items:center; gap:.4rem; padding:.55rem 1.1rem; border-radius:7px; font-size:.85rem; font-weight:500; border:none; cursor:pointer; transition:transform .15s, opacity .15s; }
        .btn:hover { transform:translateY(-1px); opacity:.9; }
        .btn-blue   { background:linear-gradient(135deg,#1f6feb,#388bfd); color:#fff; }
        .btn-green  { background:linear-gradient(135deg,#238636,#2ea043); color:#fff; }
        .btn-orange { background:linear-gradient(135deg,#9e6a03,#d29922); color:#fff; }
        .btn-ghost  { background:var(--surface2); border:1px solid var(--border); color:var(--muted); }
        .btn-sm     { padding:.35rem .75rem; font-size:.78rem; }
        .btn-row    { display:flex; gap:.6rem; flex-wrap:wrap; margin-top:1rem; }

        details summary { cursor:pointer; user-select:none; list-style:none; }
        details summary::-webkit-details-marker { display:none; }
        .chevron { display:inline-block; transition:transform .2s; margin-left:.5rem; }
        details[open] .chevron { transform:rotate(180deg); }

        table { width:100%; border-collapse:collapse; font-size:.85rem; }
        thead th { background:var(--surface2); color:var(--muted); font-weight:500; padding:.65rem 1rem; text-align:left; border-bottom:1px solid var(--border); }
        tbody tr { border-bottom:1px solid var(--border); transition:background .12s; }
        tbody tr:hover { background:rgba(88,166,255,.05); }
        td { padding:.6rem 1rem; vertical-align:middle; }
        .tag { display:inline-block; padding:.15rem .5rem; border-radius:20px; font-size:.72rem; font-weight:500; }
        .tag-active { background:rgba(63,185,80,.15); color:#3fb950; }
        .tag-disabled { background:rgba(248,81,73,.15); color:#f85149; }

        .pagination { display:flex; justify-content:center; gap:.4rem; margin-top:1.5rem; flex-wrap:wrap; }
        .page-btn { padding:.35rem .75rem; border-radius:6px; background:var(--surface2); border:1px solid var(--border); color:var(--text); cursor:pointer; font-size:.82rem; text-decoration:none; }
        .page-btn:hover, .page-btn.active { background:var(--accent); border-color:var(--accent); color:#0d1117; font-weight:600; }

        .two-col { display:grid; grid-template-columns:1fr 1fr; gap:1.5rem; }
        @media(max-width:700px){ .two-col{ grid-template-columns:1fr; } }
        .sub-title { font-size:.82rem; color:var(--muted); margin-bottom:.75rem; }
        .form-group { margin-bottom:.75rem; }
    </style>
</head>
<body>

<#assign parameters = requestParameters!{}>
<#assign customerList   = (customerList![])>
<#assign errorMessage   = (errorMessage!"")>
<#assign successMessage = (successMessage!"")>
<#assign pageSize    = 10>
<#assign currentPage = (parameters.page?has_content)?then(parameters.page?number, 1)>
<#assign totalCount  = customerList?size>
<#assign totalPages  = (totalCount > 0)?then(((totalCount - 1) / pageSize)?int + 1, 1)>
<#assign startIdx    = (currentPage - 1) * pageSize>
<#assign endIdx      = [startIdx + pageSize, totalCount]?min>
<#assign pageCustomers = (totalCount > 0)?then(customerList[startIdx..endIdx - 1]![], [])>

<header class="header">
    <span class="logo">&#128100; CustomerManagement</span>
    <span class="logo-sub">/ Find Customer</span>
</header>

<div class="container">

    <#if errorMessage?has_content>
        <div class="flash flash-error">&#9888; ${errorMessage}</div>
    </#if>
    <#if successMessage?has_content>
        <div class="flash flash-success">&#10003; ${successMessage}</div>
    </#if>

    <!-- Search -->
    <div class="card">
        <div class="card-title">&#128269; Search Customers</div>
        <form method="post" action="<@ofbizUrl>FindCustomer</@ofbizUrl>">
            <input type="hidden" name="page" value="1"/>
            <div class="form-grid">
                <div><label for="partyId">Party ID</label>
                    <input type="text" id="partyId" name="partyId" placeholder="Partial match…" value="${parameters.partyId!}"/></div>
                <div><label for="firstName">First Name</label>
                    <input type="text" id="firstName" name="firstName" placeholder="Partial match…" value="${parameters.firstName!}"/></div>
                <div><label for="lastName">Last Name</label>
                    <input type="text" id="lastName" name="lastName" placeholder="Partial match…" value="${parameters.lastName!}"/></div>
                <div><label for="emailAddress">Email Address</label>
                    <input type="text" id="emailAddress" name="emailAddress" placeholder="Partial match…" value="${parameters.emailAddress!}"/></div>
                <div><label for="contactNumber">Phone Number</label>
                    <input type="text" id="contactNumber" name="contactNumber" placeholder="Partial match…" value="${parameters.contactNumber!}"/></div>
                <div><label for="address1">Street Address</label>
                    <input type="text" id="address1" name="address1" placeholder="Partial match…" value="${parameters.address1!}"/></div>
                <div><label for="city">City</label>
                    <input type="text" id="city" name="city" placeholder="Partial match…" value="${parameters.city!}"/></div>
            </div>
            <div class="btn-row">
                <button type="submit" class="btn btn-blue">&#128269; Search</button>
                <a href="<@ofbizUrl>FindCustomer</@ofbizUrl>" class="btn btn-ghost">&#10006; Clear</a>
            </div>
        </form>
    </div>

    <!-- Create Customer -->
    <div class="card">
        <details>
            <summary>
                <div class="card-title" style="cursor:pointer;margin-bottom:0;">
                    &#43; Create New Customer <span class="chevron">&#8964;</span>
                </div>
            </summary>
            <form method="post" action="<@ofbizUrl>createCustomer</@ofbizUrl>" style="margin-top:1rem;">
                <div class="form-grid">
                    <div><label for="cc_email">Email Address *</label>
                        <input type="email" id="cc_email" name="emailAddress" required placeholder="unique@email.com"/></div>
                    <div><label for="cc_first">First Name *</label>
                        <input type="text" id="cc_first" name="firstName" required placeholder="Jane"/></div>
                    <div><label for="cc_last">Last Name *</label>
                        <input type="text" id="cc_last" name="lastName" required placeholder="Doe"/></div>
                    <div><label for="cc_phone">Phone Number</label>
                        <input type="text" id="cc_phone" name="contactNumber" placeholder="555-1234"/></div>
                    <div><label for="cc_area">Area Code</label>
                        <input type="text" id="cc_area" name="areaCode" placeholder="212"/></div>
                    <div><label for="cc_addr1">Address Line 1</label>
                        <input type="text" id="cc_addr1" name="address1" placeholder="123 Main St"/></div>
                    <div><label for="cc_city">City</label>
                        <input type="text" id="cc_city" name="city" placeholder="New York"/></div>
                    <div><label for="cc_zip">Postal Code</label>
                        <input type="text" id="cc_zip" name="postalCode" placeholder="10001"/></div>
                    <div><label for="cc_country">Country Geo ID</label>
                        <input type="text" id="cc_country" name="countryGeoId" value="USA" placeholder="USA"/></div>
                </div>
                <div class="btn-row">
                    <button type="submit" class="btn btn-green">&#43; Create Customer</button>
                </div>
            </form>
        </details>
    </div>

    <!-- Update Customer -->
    <div class="card">
        <details>
            <summary>
                <div class="card-title" style="cursor:pointer;margin-bottom:0;">
                    &#9998; Update Customer <span class="chevron">&#8964;</span>
                </div>
            </summary>
            <form method="post" action="<@ofbizUrl>updateCustomer</@ofbizUrl>" style="margin-top:1rem;">
                <div class="form-grid">
                    <div><label for="uc_email">Email Address *</label>
                        <input type="email" id="uc_email" name="emailAddress" required placeholder="existing@email.com"/></div>
                    <div><label for="uc_first">First Name</label>
                        <input type="text" id="uc_first" name="firstName" placeholder="Leave blank to keep"/></div>
                    <div><label for="uc_last">Last Name</label>
                        <input type="text" id="uc_last" name="lastName" placeholder="Leave blank to keep"/></div>
                    <div><label for="uc_phone">New Phone</label>
                        <input type="text" id="uc_phone" name="contactNumber" placeholder="New number"/></div>
                    <div><label for="uc_area">Area Code</label>
                        <input type="text" id="uc_area" name="areaCode" placeholder="212"/></div>
                    <div><label for="uc_addr1">New Address Line 1</label>
                        <input type="text" id="uc_addr1" name="address1" placeholder="New street address"/></div>
                    <div><label for="uc_city">City</label>
                        <input type="text" id="uc_city" name="city" placeholder="New city"/></div>
                    <div><label for="uc_zip">Postal Code</label>
                        <input type="text" id="uc_zip" name="postalCode" placeholder="New zip"/></div>
                    <div><label for="uc_country">Country Geo ID</label>
                        <input type="text" id="uc_country" name="countryGeoId" placeholder="USA"/></div>
                </div>
                <div class="btn-row">
                    <button type="submit" class="btn btn-orange">&#9998; Update Customer</button>
                </div>
            </form>
        </details>
    </div>

    <!-- Party Relationships -->
    <div class="card">
        <details>
            <summary>
                <div class="card-title" style="cursor:pointer;margin-bottom:0;">
                    &#128257; Party Relationships <span class="chevron">&#8964;</span>
                </div>
            </summary>
            <div class="two-col" style="margin-top:1rem;">
                <form method="post" action="<@ofbizUrl>createCustomerRelationship</@ofbizUrl>">
                    <p class="sub-title">&#9679; Establish a new relationship</p>
                    <div class="form-group"><label>Party ID From *</label>
                        <input type="text" name="partyIdFrom" required placeholder="e.g. 10000"/></div>
                    <div class="form-group"><label>Party ID To *</label>
                        <input type="text" name="partyIdTo" required placeholder="e.g. 10001"/></div>
                    <div class="form-group"><label>Relationship Type *</label>
                        <input type="text" name="partyRelationshipTypeId" required placeholder="e.g. EMPLOYMENT"/></div>
                    <div class="form-group"><label>Role From</label>
                        <input type="text" name="roleTypeIdFrom" value="CUSTOMER" placeholder="CUSTOMER"/></div>
                    <div class="form-group"><label>Role To</label>
                        <input type="text" name="roleTypeIdTo" value="CUSTOMER" placeholder="CUSTOMER"/></div>
                    <button type="submit" class="btn btn-blue btn-sm">Create Relationship</button>
                </form>
                <form method="post" action="<@ofbizUrl>updateCustomerRelationship</@ofbizUrl>">
                    <p class="sub-title">&#9679; Update existing relationship</p>
                    <div class="form-group"><label>Party ID From *</label>
                        <input type="text" name="partyIdFrom" required placeholder="e.g. 10000"/></div>
                    <div class="form-group"><label>Party ID To *</label>
                        <input type="text" name="partyIdTo" required placeholder="e.g. 10001"/></div>
                    <div class="form-group"><label>Relationship Type *</label>
                        <input type="text" name="partyRelationshipTypeId" required placeholder="e.g. EMPLOYMENT"/></div>
                    <div class="form-group"><label>Role From *</label>
                        <input type="text" name="roleTypeIdFrom" required value="CUSTOMER"/></div>
                    <div class="form-group"><label>Role To *</label>
                        <input type="text" name="roleTypeIdTo" required value="CUSTOMER"/></div>
                    <div class="form-group"><label>From Date *</label>
                        <input type="datetime-local" name="fromDate" required/></div>
                    <div class="form-group"><label>New Status</label>
                        <input type="text" name="statusId" placeholder="e.g. PARTY_REL_ACTIVE"/></div>
                    <div class="form-group"><label>Comments</label>
                        <input type="text" name="comments" placeholder="Optional notes"/></div>
                    <button type="submit" class="btn btn-orange btn-sm">Update Relationship</button>
                </form>
            </div>
        </details>
    </div>

    <!-- Results -->
    <div class="card">
        <div class="card-title">
            &#128202; Results
            <span style="font-size:.78rem;color:var(--muted);font-weight:400;margin-left:.5rem;">
                (${totalCount} customer${(totalCount != 1)?then("s","")}) — Page ${currentPage} of ${totalPages}
            </span>
        </div>
        <#if pageCustomers?has_content>
        <div style="overflow-x:auto;">
            <table>
                <thead>
                    <tr>
                        <th>Party ID</th>
                        <th>First Name</th>
                        <th>Last Name</th>
                        <th>Email</th>
                        <th>Phone</th>
                        <th>Address</th>
                        <th>City</th>
                        <th>Postal Code</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <#list pageCustomers as c>
                    <tr>
                        <td><strong>${c.partyId!"-"}</strong></td>
                        <td>${c.firstName!"-"}</td>
                        <td>${c.lastName!"-"}</td>
                        <td>${c.emailAddress!"-"}</td>
                        <td>
                            <#if c.contactNumber?has_content>
                                ${c.areaCode!""} ${c.contactNumber}
                            <#else>—</#if>
                        </td>
                        <td>${c.address1!"-"}</td>
                        <td>${c.city!"-"}</td>
                        <td>${c.postalCode!"-"}</td>
                        <td>
                            <#if c.statusId?? && c.statusId == "PARTY_ENABLED">
                                <span class="tag tag-active">Active</span>
                            <#else>
                                <span class="tag tag-disabled">${c.statusId!"-"}</span>
                            </#if>
                        </td>
                    </tr>
                    </#list>
                </tbody>
            </table>
        </div>
        <#if totalPages gt 1>
        <div class="pagination">
            <#list 1..totalPages as pg>
                <a href="<@ofbizUrl>FindCustomer?partyId=${parameters.partyId!}&amp;firstName=${parameters.firstName!}&amp;lastName=${parameters.lastName!}&amp;emailAddress=${parameters.emailAddress!}&amp;page=${pg}</@ofbizUrl>"
                   class="page-btn <#if pg == currentPage>active</#if>">${pg}</a>
            </#list>
        </div>
        </#if>
        <#else>
        <p style="color:var(--muted);text-align:center;padding:2rem 0;">
            No customers found. Use the search filters above or create a new customer.
        </p>
        </#if>
    </div>

</div>
</body>
</html>
