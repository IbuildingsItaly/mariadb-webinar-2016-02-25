/*
        This file contains the examples used to demonstrate InnoDB Page Compression.
*/


USE test;


/*
        Populate an uncompressed table and check size
*/

SET GLOBAL innodb_file_per_table := 1;
CREATE /*M!100000 OR REPLACE */ TABLE t_uncompressed (
        a INT AUTO_INCREMENT PRIMARY KEY,
        b BIGINT,
        c BIGINT,
        INDEX idx_b (b),
        INDEX idx_c (c)
)
        ENGINE = InnoDB;

INSERT INTO t_uncompressed (a, b, c)
        SELECT NULL, TRUNCATE(RAND() * 2000, 0), TRUNCATE(RAND() * 100, 0)
        FROM seq_1_to_1000000;

\! ls -l /var/lib/mysql/test/t_uncompressed.ibd | awk '{ print $5 }'



/*
        Populate a compressed table and check size
*/

SET GLOBAL innodb_compression_algorithm = 'lzma';
SET GLOBAL innodb_compression_level = 6;

CREATE /*M!100000 OR REPLACE */ TABLE t_compressed (
        a INT AUTO_INCREMENT PRIMARY KEY,
        b BIGINT,
        c BIGINT,
        INDEX idx_b (b),
        INDEX idx_c (c)
)
        ENGINE = InnoDB
        PAGE_COMPRESSED = 1;

INSERT INTO t_compressed (a, b, c)
        SELECT NULL, TRUNCATE(RAND() * 2000, 0), TRUNCATE(RAND() * 100, 0)
        FROM seq_1_to_1000000;

\! ls -l /var/lib/mysql/test/t_compressed.ibd | awk '{ print $5 }'


