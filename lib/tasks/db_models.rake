namespace :db do
    desc 'Generate models for all database tables'
    task generate_models: :environment do
      ActiveRecord::Base.connection.tables.each do |table_name|
        model_name = table_name.singularize.camelize
        next if Object.const_defined?(model_name)
        
        system "rails generate model #{model_name}"
      end
    end
  end
  