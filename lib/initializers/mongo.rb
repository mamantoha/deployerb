mongo_settings = YAML.load(File.read(File.expand_path('../../config/mongo.yml', File.dirname(__FILE__))))['development']

MongoMapper.connection = Mongo::Connection.new(mongo_settings['host'], mongo_settings['port'], logger: $logger)
MongoMapper.logger
MongoMapper.database = mongo_settings['database']

if mongo_settings['username'] && mongo_settings['password']
  MongoMapper.database.authenticate(mongo_settings['username'], mongo_settings['password'])
end
