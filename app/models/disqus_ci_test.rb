require 'open-uri'

class DisqusCiTest < ActiveRecord::Base
  unloadable
  belongs_to :repository
  belongs_to :user
  belongs_to :changeset
  has_many :messages, :class_name => 'DisqusCiTestMessage', :foreign_key => 'test_id'
  
  validates_presence_of :repository_id, :branch, :revision, :changeset_id
  validates_uniqueness_of :revision, :scope => :repository_id
  
  def revision=(r)
    write_attribute :revision, (r.nil? ? nil : r.to_s)
  end
  
  def successful?
    total_passed.to_i == total_tests.to_i && total_tests.to_i > 0
  end
  
  def total_failures
    total_tests.to_i - total_passed.to_i
  end
  
  def project
    repository.project
  end
  
  def author
    changeset.user
  end
  
  def self.fetch_revision(project, revision_id)
    tessie_url = project.custom_values.detect {|v| v.custom_field_id == Setting.plugin_disqus_ci['tessie_url_custom_field'].to_i}
    tessie_url = tessie_url.value if tessie_url
    
    begin
      content = ''
      # Open the feed and parse it
      tessie_url = tessie_url + '/api/commits/' + revision_id + '.json'

      changeset = Changeset.find(:first, :conditions => ['revision = ? AND repository_id = ?', revision_id, project.repository.id])
      if not changeset
        return
      end
      change = changeset.changes.find(:first)
      if not change
        return
      end
      branch = change.branch
      if not branch
        branch = change.path.split('/')
        if branch[1] == 'branches'
          branch = branch[2]
        else
          branch = branch[1]
        end
      end
      
      open(tessie_url) do |s| content = s.read end
      hash = ActiveSupport::JSON.decode(content)
      if hash
        DisqusCiTest.transaction do
          test = DisqusCiTest.create do |t|
            t.repository_id = project.repository.id
            t.branch = hash['branch']['name']
            t.revision = revision_id
            t.changeset_id = changeset.id
            t.message = hash['message']
            t.exception = hash['exception']
            t.tested_on = hash['date']
            t.total_passed = hash['total_passed'].to_i
            t.total_tests = hash['total_tests'].to_i
            t.total_skipped = hash['tests']['skipped'].length
          end
          if test.errors
            return
          end
          ['errors', 'failures', 'skipped'].each do |reason|
            hash['tests'][reason].each do |r|
              message = DisqusCiTestMessage.create do |t|
                t.reason = reason
                t.name = r['name']
                t.traceback = r['traceback']
                t.test_id = test.id
              end
            end
          end
        end
      end
    rescue OpenURI::HTTPError
      # puts 'HTTPError: Unable to connect to remote host, storing empty build.'
      # test = DisqusCiTest.create do |t|
      #   t.repository_id = project.repository.id
      #   t.branch = branch
      #   t.revision = revision_id
      #   t.changeset_id = changeset.id
      # end
    rescue SocketError
      puts 'SocketError: Unable to connect to remote host.'
    end
  end

  def self.fetch_missing_tests
    Project.active.has_module(:repository).find(:all, :include => :repository).each do |project|
      if project.repository
        commit_date = Changeset.maximum('commit_date', :conditions => ['id IN (select changeset_id from disqus_ci_tests where repository_id = ?)', project.repository])
        changesets = project.repository.changesets.find(:all, :conditions => commit_date ? ['commit_date > ?', commit_date] : [], :select => :revision)

        changesets.each do |c|
          DisqusCiTest.fetch_revision(project, c.revision)
        end
      end
    end
  end
end

class DisqusCiTestMessage < ActiveRecord::Base
  unloadable
  belongs_to :disqus_ci_test, :foreign_key => :test_id
  validates_presence_of :name, :traceback
end
  