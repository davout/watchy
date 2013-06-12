# Watchy, a flexible database audit and monitoring framework

## Data audit

Watchy allows you to easily monitor any database by enforcing configurable contraints on the data.

It possible to specify which tables should be monitored and what what constraints should be enforced.

Anything that is not explicitly allowed is forbidden.

It is for example possible to enforce that :
 
 * Rows only get appended to a table
 * Only certain fields of existing rows can change, and define what transitions are acceptable
 * Aggregates respect arbitrary conditions


## Reporting

Watchy can be configured to generate and publish reports on the audited data.


## Requirements

 * Currently Watchy supports only MySQL databases.
 * The audit database will always be created on the same server as the audited data, it is therefore desirable that updates happen through a one-way mechanism, MySQL database replication being perfectly suited for this purpose.
