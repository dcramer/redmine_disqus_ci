class DisqusCiController < ApplicationController
  unloadable
  layout 'base'
  before_filter :find_project
  
  def show
    @branches = DisqusCiTest.find(:all, :group => :branch, :select => :branch)
    @tests = [];
    @branches.each do |d|
      @tests |= DisqusCiTest.find(:all, 
                               :conditions => ['repository_id = ? and tested_on is not null and branch = ?', @project.repository, d.branch],
                               :order => 'tested_on desc',
                               :limit => 10)
    end
  end

  def details
    @test = DisqusCiTest.find(:first, :conditions => {:revision => params[:revision]})
  end

  
private
  def find_project   
    @project = Project.find(params[:id], :include => :repository)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
