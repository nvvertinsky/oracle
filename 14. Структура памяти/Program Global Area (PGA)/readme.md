# PGA. Глобальная область процесса. Process Global Area


### Описание: 
  - Это область памяти выделенного серверного процесса.
  - Другие процессы не имеют доступа к ней.
  - То есть допустим клиент подключится к базе данных, ему создали процесс на сервере. И этому процессу выделяется память.

### Что хранит: 
  - Рабочая область памяти: 
    - Область сортировки
      - group by
	  - order by 
    - Область хеширования
	  - При хеш соединении таблиц строит хеш таблицы здесь
    - Область слияния битовых индексов
    - Значения локальных переменных
    - Пакетный кеш
  
  - Приватная область памяти
    - Привязанные переменные (bind variables). Например когда выполняется SQL или PL/SQL
	- Курсоры. (область памяти с результатами данных запроса)
  
### Если не хватает памяти
  - Сбрасывает часть данный на диск в табличное пространство TEMP

### Режим управления: 
  - Автоматическое управление памятью (AMM).
    - Применяется к PGA и SGA.
	- Доступно только с 11g.
	- Нужно установить всего один параметр MEMORY_TARGET.
	- Oracle сам распределит память SGA, PGA как ему надо.
  
  - Автоматическое управление памятью PGA.
    - Нужно установить размер параметра PGA_AGGREGATE_TARGET
	- Какой режим выбран контролирует параметр WORKAREA_SIZE_POLICY
  
  - Ручное управление PGA
    - Нужно вручную выставлять параметры SORT_AREA_SIZE, HASH_AREA_SIZE. Это значения определяеют лимиты для одиночной операции. Внутри сеанса могут выполняться много запросов. Так же если эти значения поставить в 1гб, это не значит что будет каждый раз использовать 1 гб. 
		- SORT_AREA_SIZE - Объем памяти для сортировки данных.
		- SORT_AREA_RETAINED_SIZE - Объем памяти, который используется для хранения остортированных данных. Если места не хватит, то как обычно скидываем в TEMP
		- HASH_AREA_SIZE - Объем памяти, для хранения хеш-таблиц. Когда происходит хеш соединение таблиц.
	- Какой режим выбран контролирует параметр WORKAREA_SIZE_POLICY
	
### Примеры 

Сначала смотрим сколько PGA занимает наш процесс:

````
select t.sid, 
       t.serial#, 
       t.osuser, 
       t.machine, 
       t.program,
       t.status,
       t.module,
       t.client_info,
       t.prev_exec_start,
       t.logon_time,
       round(p.PGA_USED_MEM / 1024 / 1024, 2) || ' mb' pga_used,
       round(p.PGA_ALLOC_MEM / 1024 / 1024, 2) || ' mb' pga_alloc,
       round(p.PGA_FREEABLE_MEM / 1024 / 1024, 2) || ' mb' freeable_mem
  from v$session t,
       v$process p
 where upper(t.OSUSER) != upper('oracle')
   and t.type = 'USER'
   and p.addr = t.paddr
   and t.SID = SYS_CONTEXT('USERENV','SID')
 order by t.machine asc;
````

Дальше заполняем PGA данными: 

````
begin
  tpkg.fill_pga(1000000);
end; 
````

Память заполнилась на 80 мб. Освобождаем память. 

````
begin
  tpkg.flush_pga;
end; 
````

Но видим что PGA все так же занимает 80 мб. Дело в том что память уже выделена, просто она пустая. Можно еще раз заполнить память на 80мб. 
Занимаемое место не увеличиться. 

Чтобы полностью сбросить память можно вызвать: 

````
begin
  dbms_session.reset_package();
end;
````