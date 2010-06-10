class Setup < ActiveRecord::Migration
  def self.up
    create_table :disqus_ci_tests do |t|
      t.column :repository_id, :integer, :null => false
      t.column :changeset_id, :integer, :null => false
      t.column :branch, :string, :null => false
      t.column :revision, :string, :null => false
      t.column :tested_on, :datetime
      t.column :message, :text
      t.column :exception, :text
      t.column :total_passed, :integer
      t.column :total_skipped, :integer
      t.column :total_tests, :integer
    end
    add_index :disqus_ci_tests, [:repository_id, :revision], :unique => true, :name => :tests_repos_rev
    
    create_table :disqus_ci_test_messages do |t|
      t.column :reason, :string
      t.column :test_id, :integer, :null => false
      t.column :name, :string
      t.column :traceback, :text
    end
  end

  def self.down
    drop_table :disqus_ci_tests
    drop_table :disqus_ci_test_messages
  end
end
