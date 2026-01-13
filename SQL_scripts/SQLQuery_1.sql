--create ETL schema
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'etl')
BEGIN
    EXEC('CREATE SCHEMA etl');
END
GO

--create the config table

IF OBJECT_ID('etl.pipeline_config', 'U') IS NULL
BEGIN
  CREATE TABLE etl.pipeline_config (
      config_id      INT IDENTITY(1,1) PRIMARY KEY,
      pipeline_name  VARCHAR(200) NOT NULL,
      env            VARCHAR(20)  NOT NULL,      -- dev/test/prod
      country        CHAR(2)      NOT NULL,      -- NG, CA
      dataset        VARCHAR(50)  NOT NULL DEFAULT 'osm',
      raw_path       VARCHAR(500) NOT NULL,
      bronze_path    VARCHAR(500) NOT NULL,
      active         BIT NOT NULL DEFAULT 1,
      created_at_utc DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );

  CREATE INDEX IX_pipeline_config_lookup
  ON etl.pipeline_config(pipeline_name, env, country, active);
END
GO
