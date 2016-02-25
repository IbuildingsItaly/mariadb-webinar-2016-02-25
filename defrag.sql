/*
        This file contains the examples used to demonstrate InnoDB defragmentation.
*/


USE test;


/*
        The tabke we'll populate.
        
        OR REPLACE improves usability and reduces replication failures
        (in case the table has been dropped on a slave).
        In MariaDB 10.1, all CREATE/DROP statements
        have OR REPLACE and IF [NOT] EXISTS.
        
        The executable comment is executed on MariaDB (M)
        version 10.00.00 or higher (100000).
        Without M it would be executed by MySQL too.
        Version number is optional.
*/
SET GLOBAL innodb_file_per_table := 1;
CREATE /*M!100000 OR REPLACE */ TABLE t (
        a INT AUTO_INCREMENT PRIMARY KEY,
        b BIGINT,
        c BIGINT,
        INDEX idx_b (b),
        INDEX idx_c (c)
);


/*
        Let's populate the table with 3 mln rows.
        This operation is quite common in tests,
        so I'll show 3 methods to do it.
        With MariaDB, I always use the 3rd.
*/


/*
        Slowest way: takes 1 minute + 8 seconds on my machine.
        We insert all rows within the same transaction (less overhead).
        BEGIN NOT ATOMIC requires MariaDB - on MySQL you need a stored procedure.
*/
DELIMITER ||
BEGIN NOT ATOMIC
START TRANSACTION;
SET @i := 1000000;
WHILE @i > 0 DO
        INSERT INTO t VALUES (DEFAULT, TRUNCATE(RAND() * 2000, 0), TRUNCATE(RAND() * 100, 0));
        SET @i := @i - 1;
END WHILE;
COMMIT;
END ||
DELIMITER ;


/*
        Much faster, less randomity: 17 seconds on my machine.
*/
INSERT INTO t SELECT NULL AS a, b, c FROM t;


/*
        Faster, requires SEQUENCE storage engine (MariaDB only):
        15 second on my machine.
*/
INSERT INTO t (a, b, c)
        SELECT NULL, TRUNCATE(RAND() * 2000, 0), TRUNCATE(RAND() * 100, 0)
        FROM seq_1_to_1000000;



/*
        If everything worked, now we have 3 mln rows.
        Let's see how big is the tablespace.
        100663296
*/
SELECT COUNT(*) FROM t;
\! ls -l /var/lib/mysql/test/t.ibd | awk '{ print $5 }'


/*
        What happens if we delete many rows?
        100663296
*/
DELETE FROM t WHERE a < 500000;
DELETE FROM t WHERE a BETWEEN 1500000 AND 2000000;
SELECT COUNT(*) FROM t;
\! ls -l /var/lib/mysql/test/t.ibd | awk '{ print $5 }'
SELECT DATA_FREE /1024/1024 AS unused_space_mb
        FROM information_schema.TABLES 
        WHERE TABLE_SCHEMA = 'test' AND TABLE_NAME = 't';
SELECT INDEX_NAME, SUM(NUMBER_RECORDS), SUM(DATA_SIZE)
        FROM information_schema.INNODB_BUFFER_PAGE
        WHERE TABLE_NAME = '`test`.`t`'
        GROUP BY INDEX_NAME;


/*
        Now let's defragment and check again!
*/
SET GLOBAL innodb_defragment := 1;
OPTIMIZE TABLE t;
SET GLOBAL innodb_defragment := 0;
\! ls -l /var/lib/mysql/test/t.ibd | awk '{ print $5 }'
SELECT DATA_FREE /1024/1024 AS unused_space_mb
        FROM information_schema.TABLES 
        WHERE TABLE_SCHEMA = 'test' AND TABLE_NAME = 't';
SELECT INDEX_NAME, SUM(NUMBER_RECORDS), SUM(DATA_SIZE)
        FROM information_schema.INNODB_BUFFER_PAGE
        WHERE TABLE_NAME = '`test`.`t`'
        GROUP BY INDEX_NAME;

