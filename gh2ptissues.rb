#!/usr/bin/env ruby

# Author:       Russ Brooks, TelVue Corporation (www.telvue.com)
# Description:  Migrates GitHub Issues to Pivotal Tracker.
# Dependencies: Ruby 1.9.2+
#               GitHub API gem: https://github.com/peter-murach/github
#               Pivtal Tracker gem: https://github.com/jsmestad/pivotal-tracker
#   1. Change the constants below accordingly for your project.
#   2. Change the options in list_repo() method for your GitHub project.
#   3. Change the options in stories.create() method accordingly.
#   4. Change the options in notes.create() method accordingly.
#   5. gem install github_api
#   6. gem install pivotal-tracker
#   7. Save this code to a .rb file (gh_to_pt.rb), and chmod it executable [775].
#   8. Run this file: ./gh_to_pt.rb
#
# Dry-run it first by commenting the create() methods below.
#
# TODO: Exceoption handling. Pivotal create operations just silently fail right now.
#       You have to just observe your Pivotal project immeidately afterwards.

GITHUB_ORG = '***'
GITHUB_USER = 'shyam-habarakada'
GITHUB_REPO = '***'
GITHUB_LOGIN = 'shyam-habarakada'
GITHUB_PASSWORD = '*******'
PIVOTAL_TOKEN = '****************'
PIVOTAL_PROJECT_ID = '******'

require 'rubygems'
require 'github_api'
require 'pivotal-tracker'


# Get a single issue:
#issue = github.issues.find(GITHUB_USER, GITHUB_REPO, 301)
# Careful when getting a single issue. The signature of the objects
# returned is different than when iterating issues.list_repo().
# IOW, some stuff below breaks.

PivotalTracker::Client.token = PIVOTAL_TOKEN
# proj = PivotalTracker::Project.find(PIVOTAL_PROJECT_ID)

# 100 per page is max, so we can iterate all pages like this:
# issues.each_page do |page|
#   page.each do |issue|
#     p issue.id
#   end
# end
# But paging like that causes it to not pay attention to
# any filering above in the list_repo() method options.
# So we have to break thing up into sub-100 chunks.

github = Github.new org: GITHUB_ORG, repo: GITHUB_REPO, login: GITHUB_LOGIN, password: GITHUB_PASSWORD
issues = github.issues.list(:filter => 'all', :state => 'open', :sort => 'created')

i = 0

issues.each_page do |page|
  page.each do |issue|
    # labels = issue.labels.select { |k,v| k == "name" }
    puts "issue: #{issue.title} (#{issue.number})"

    # puts JSON.pretty_generate(issue)

    comments = github.issues.comments.list GITHUB_ORG, GITHUB_REPO, :issue_id => issue.number
    comments.each_page do |comments_page|
      comments_page.each do |comment|
        puts "  comment: #{comment.body}"
      end
    end

    # puts issue.body

    # # Create story in Pivotal Tracker
    # story = proj.stories.create(
    #   name: issue.title,
    #   description: issue.body,
    #   created_at: issue.created_at,
    #   # labels: 'Request',
    #   # owned_by: issue.assignee.login,
    #   # requested_by: issue.user.login,
    #   story_type: 'bug', # 'bug', 'feature', 'chore', 'release'. Omitting makes it a feature.
    #   current_state: 'unstarted' # 'unstarted', 'started', 'accepted', 'delivered', 'finished', 'unscheduled'.
    #   # Omitting puts it in the Icebox.
    #   # 'unstarted' puts it in 'Current' if Commit Mode is on; 'Backlog' if Auto Mode is on.
    # )

    # comments = github.issues.comments.all 'telvue', 'Connect', issue.number
    # comments.each do |comment|
    #   puts '--------------'
    #   puts 'ADDING COMMENT'
    #   puts 'From: ' + comment.user.login
    #   puts 'Date: ' + comment.created_at
    #   puts ''
    #   puts comment.body

      # story.notes.create(
      #   text: comment.body.gsub(/\r\n\r\n/, "\n\n"),
      #   author: comment.user.login,
      #   noted_at: comment.created_at
      # )
    # end
    i = i + 1
  end
end

puts '=============='
puts 'TOTAL MIGRATED: ' + i.to_s
puts '=============='