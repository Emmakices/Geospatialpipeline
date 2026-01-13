DELETE FROM etl.pipeline_config
WHERE pipeline_name='geospatial-pipeline' AND env='dev' AND country='NG';

INSERT INTO etl.pipeline_config (pipeline_name, env, country, dataset, raw_path, bronze_path, active)
VALUES (
  'geospatial-pipeline',
  'dev',
  'NG',
  'osm',
  'abfss://raw-osm@geopipe2325dl.dfs.core.windows.net/nigeria/',
  'abfss://bronze@geopipe2325dl.dfs.core.windows.net/osm/',
  1
);
GO
