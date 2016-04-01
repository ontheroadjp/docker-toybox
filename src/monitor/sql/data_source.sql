INSERT INTO data_source(org_id,version,type,name,access,url,password,user,database,basic_auth,basic_auth_user,basic_auth_password,is_default,json_data,created,updated,with_credentials) VALUES(1,0,'graphite','Graphite','proxy','http://graphite','','','',1,'guest','guest',1,'{}','2016-03-31 15:39:16','2016-03-31 15:39:19',0);
INSERT INTO data_source(org_id,version,type,name,access,url,password,user,database,basic_auth,basic_auth_user,basic_auth_password,is_default,json_data,created,updated,with_credentials) VALUES(1,0,'influxdb_08','influxdb','proxy','http://influxdb:8086','root','root','cadvisor',1,'root','root',0,'{}','2016-03-31 15:42:10','2016-03-31 15:42:14',0);
-- INSERT INTO "data_source()" VALUES(1,1,0,'graphite','Graphite','proxy','http://graphite','','','',1,'guest','guest',1,'{}','2016-03-31 15:39:16','2016-03-31 15:39:19',0);
-- INSERT INTO "data_source" VALUES(2,1,0,'influxdb_08','influxdb','proxy','http://influxdb:8086','root','root','cadvisor',1,'root','root',0,'{}','2016-03-31 15:42:10','2016-03-31 15:42:14',0);
-- CREATE INDEX `IDX_data_source_org_id` ON `data_source` (`org_id`);
-- CREATE UNIQUE INDEX `UQE_data_source_org_id_name` ON `data_source` (`org_id`,`name`);
-- COMMIT;
