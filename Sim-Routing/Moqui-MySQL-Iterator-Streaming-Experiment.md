# Moqui MySQL Streaming — Experiment Report

**Date:** June 26, 2026

**Purpose:** Does Moqui's `.iterator()` truly stream rows one-by-one, or does it load everything into memory at once?

---

## The Question

When we call `ec.entity.find("...").iterator()` on a large MySQL table, does Moqui:

- **Stream rows one-by-one** (safe — memory stays flat), OR
- **Load the entire table into RAM first** (dangerous — causes crash on large data)

---

### JVM Baseline (unconstrained server)

Before applying constraints, we checked the server's default memory headroom:

```text
======================================================
 JVM MEMORY REPORT
======================================================
  Max Memory   (JVM ceiling / -Xmx) : 3,934 MB
  Total Memory (allocated from OS)  :   224 MB
  Free Memory  (allocated, unused)  :   138 MB
  Used Memory  (in active use now)  :    86 MB
======================================================
```

| Metric | Value | What it means |
|:---|:---|:---|
| Max Memory | 3,934 MB | JVM can grow up to this — the hard ceiling |
| Total Memory | 224 MB | Heap currently claimed from OS |
| Free Memory | 138 MB | Claimed but idle — no live objects yet |
| Used Memory | 86 MB | Actively used by live Java objects |

> At 3.9 GB ceiling, the JVM would silently absorb the entire 200,000-row table without crashing — giving a false sense of safety. This is why we needed a memory trap.

### Framework Code — What Was Verified

**`EntityFindBase.groovy` (lines 52, 81) — cursor type:**
```text
grep output:
  52: final static int defaultResultSetType = ResultSet.TYPE_FORWARD_ONLY
  81: protected int resultSetConcurrency   = ResultSet.CONCUR_READ_ONLY
```

**`EntityFindBuilder.java` (lines 779, 783) — fetch size guard:**
```text
grep output:
  779: Integer fetchSize = entityFindBase.getFetchSize();
  783: if (fetchSize != null && fetchSize > 0) { ps.setFetchSize(fetchSize); } else { ps.setFetchSize(100); }
```

> `TYPE_FORWARD_ONLY` + `CONCUR_READ_ONLY` looks like streaming — but fetch size = 100 (positive) tells MySQL Connector/J to buffer everything. Only `Integer.MIN_VALUE` (-2,147,483,648) triggers true row-by-row streaming. Moqui's guard blocks that.

---

## Test 1 — Normal Run (default Moqui config)

Moqui's default `mysql8` profile silently adds `useCursorFetch=true` to the connection. We ran the `run#MemoryExperiment` service with no changes.

**Result: No crash. Memory stayed flat.**

```text
00:06:45.891  INFO  o.moqui.i.c.LoggerFacadeImpl
======================================================
 EXPERIMENT: MOQUI ITERATOR
======================================================
Memory BEFORE test : 63 MB
  -> Read  50,000 rows. Current Memory: 63 MB
  -> Read 100,000 rows. Current Memory: 63 MB
  -> Read 150,000 rows. Current Memory: 63 MB
  -> Read 200,000 rows. Current Memory: 63 MB

Memory AFTER test        : 63 MB
Total Memory Difference  :  0 MB
Time Taken               : 4,023 ms
Total Rows Processed     : 200,000
======================================================
```

| Metric | Value |
|:---|:---|
| Memory Before | 63 MB |
| Memory at 50K rows | 63 MB |
| Memory at 100K rows | 63 MB |
| Memory at 150K rows | 63 MB |
| Memory at 200K rows | 63 MB |
| Memory After | 63 MB |
| **Memory Growth** | **0 MB** |
| Time Taken | 4,023 ms (~4 sec for 200K rows) |
| Rows/second | ~49,700 rows/sec |

> This passed **only because** `useCursorFetch=true` was secretly active in Moqui's connection profile. It is NOT proof that Moqui streams natively.

---

## Test 2 — Decisive Run (safety net removed)

We stripped out `useCursorFetch` by overriding the JDBC URL directly in `MoquiDevConf.xml`:

```xml
<entity-facade query-stats="true">
    <datasource group-name="transactional" database-conf-name="mysql8" schema-name="">
        <inline-jdbc jdbc-driver="com.mysql.cj.jdbc.Driver"
                     jdbc-uri="jdbc:mysql://127.0.0.1:3306/moqui?useCursorFetch=false&amp;useSSL=false&amp;allowPublicKeyRetrieval=true&amp;serverTimezone=UTC"
                     jdbc-username="root"
                     jdbc-password="123456"/>
    </datasource>
</entity-facade>
```

Then started the server with only **256 MB** of heap (a deliberate trap — since ~430–640 MB is needed to buffer the table):

```bash
java -Xmx256m -jar moqui.war -conf=conf/MoquiDevConf.xml
```

**Result: Crash.**

```text
org.moqui.impl.entity.EntitySqlException: Error finding list of TestStreaming by null [S1000]
...
Caused by: java.sql.SQLException: Java heap space
...
Caused by: java.lang.OutOfMemoryError: Java heap space
    at com.mysql.cj.protocol.a.NativeProtocol.readAllResults(NativeProtocol.java:1713)
```

| Metric | Value |
|:---|:---|
| JVM Heap Cap | 256 MB (`-Xmx256m`) |
| Data on disk | ~215 MB |
| Estimated in-heap need | ~430–640 MB |
| Gap (heap needed vs allowed) | **174–384 MB over the limit** |
> The stack trace shows `readAllResults()` — MySQL tried to load all 200,000 rows into a 256 MB heap before handing back even the first row.

---

## Why Does This Happen?

Moqui's `EntityFindBuilder.java` line 783 always forces a **positive** fetch size:

```java
if (fetchSize != null && fetchSize > 0) { ps.setFetchSize(fetchSize); }
else { ps.setFetchSize(100); }  // ← always falls here — blocks MIN_VALUE
```

MySQL Connector/J streaming rule:

| Fetch Size Sent | MySQL Connector/J Behaviour |
|:---|:---|
| Any positive number (e.g. 100) | Buffer entire result set before returning row 1 |
| `Integer.MIN_VALUE` (-2,147,483,648) | Stream row-by-row (true lazy fetch) |

Since Moqui only ever sends `100`, MySQL always buffers everything first.

---

## Conclusion

| Scenario | Connection Setting | Memory Behaviour | Crash? |
|:---|:---|:---|:---|
| Default Moqui `mysql8` profile | `useCursorFetch=true` (hidden) | Flat 63 MB across 200K rows |  No |
| Inline JDBC, `useCursorFetch=false` | Pure JDBC default | Spikes — full table buffered |  Yes |

**The `.iterator()` API looks lazy, but it is not — MySQL buffers everything unless `useCursorFetch=true` is enforced.**

---

## What To Do

**For the sync engine:** Use raw JDBC with `setFetchSize(Integer.MIN_VALUE)` to guarantee true streaming:

```java
PreparedStatement ps = conn.prepareStatement(sql,
    ResultSet.TYPE_FORWARD_ONLY,
    ResultSet.CONCUR_READ_ONLY);
ps.setFetchSize(Integer.MIN_VALUE); // ← only way MySQL actually streams
```

**For general Moqui development:** Always ensure `useCursorFetch=true` is present in the connection profile when iterating large tables.

---

## Code Used

### Entity (`ExperimentEntities.xml`)

```xml
<entity entity-name="TestStreaming" package="sim.routing">
    <field name="testId" type="id"  is-pk="true"/>  
    <field name="randomDataA" type="text-medium"/>                
    <field name="randomDataB" type="text-medium"/>                
    <field name="randomDataC" type="text-medium"/>                
</entity>
```

### Data Pump (`DataPump.groovy`) — fills the table with 200,000 rows

```groovy
for (int i = 1; i <= 200000; i++) {
    EntityValue ev = ef.makeValue("sim.routing.TestStreaming")
    ev.set("testId",      "TEST_" + i)
    ev.set("randomDataA", UUID.randomUUID().toString().padRight(250, 'A'))  
    ev.set("randomDataB", UUID.randomUUID().toString().padRight(250, 'B'))  
    ev.set("randomDataC", UUID.randomUUID().toString().padRight(250, 'C'))  
    ev.create()
    if (i % 1000 == 0) ec.logger.info("Pumped ${i} rows...")
}
```

### Memory Test (`MemoryExperiment.groovy`) — samples heap every 50,000 rows

```groovy
def getMemMB = { -> System.gc(); sleep(100); return (rt.totalMemory() - rt.freeMemory()) >> 20 }

EntityListIterator eli = ec.entity.find("sim.routing.TestStreaming").iterator()
try {
    EntityValue ev
    while ((ev = eli.next()) != null) {
        count++
        if (count % 50000 == 0)
            report.append("  -> Read ${count} rows. Current Memory: ${getMemMB()} MB\n")
    }
} finally {
    eli.close()
}
```

