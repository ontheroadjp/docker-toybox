CREATE TABLE `data_source` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL
    , `org_id` INTEGER NOT NULL
    , `version` INTEGER NOT NULL
    , `type` TEXT NOT NULL
    , `name` TEXT NOT NULL
    , `access` TEXT NOT NULL
    , `url` TEXT NOT NULL
    , `password` TEXT NULL
    , `user` TEXT NULL
    , `database` TEXT NULL
    , `basic_auth` INTEGER NOT NULL
    , `basic_auth_user` TEXT NULL
    , `basic_auth_password` TEXT NULL
    , `is_default` INTEGER NOT NULL
    , `json_data` TEXT NULL
    , `created` DATETIME NOT NULL
    , `updated` DATETIME NOT NULL
    , `with_credentials` INTEGER NOT NULL DEFAULT 0);
-- CREATE INDEX `IDX_data_source_org_id` ON `data_source` (`org_id`);
-- CREATE UNIQUE INDEX `UQE_data_source_org_id_name` ON `data_source` (`org_id`,`name`);

INSERT INTO data_source(org_id,version,type,name,access,url,password,user,database,basic_auth,basic_auth_user,basic_auth_password,is_default,json_data,created,updated,with_credentials) VALUES(1,0,'graphite','Graphite','proxy','http://graphite','','','',1,'guest','guest',1,'{}','2016-03-31 15:39:16','2016-03-31 15:39:19',0);
INSERT INTO data_source(org_id,version,type,name,access,url,password,user,database,basic_auth,basic_auth_user,basic_auth_password,is_default,json_data,created,updated,with_credentials) VALUES(1,0,'influxdb_08','influxdb','proxy','http://influxdb:8086','root','root','cadvisor',1,'root','root',0,'{}','2016-03-31 15:42:10','2016-03-31 15:42:14',0);
