-- Транзакция 1
select val from tst where val = 'tstval';
/* 0 rows */

-- Транзакция 2
insert into tst (id, val) values (3, 'tstval');

-- Транзакция 1
select val from tst where val = 'tstval';
/* 0 rows */