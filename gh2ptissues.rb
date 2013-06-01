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

GITHUB_USER = 'telvue'
GITHUB_REPO = 'Connect'
GITHUB_LOGIN = 'rbrooks'
GITHUB_PASSWORD = '************'
PIVOTAL_TOKEN = 'ff90000000f123c71e12cca9ead123aa'
PIVOTAL_PROJECT_ID = '1234567'

require 'rubygems'
require 'github_api'
require 'pivotal-tracker'

github = Github.new user: GITHUB_USER, repo: GITHUB_REPO, login: GITHUB_LOGIN, password: GITHUB_PASSWORD
issues = github.issues.list_repo(GITHUB_USER, GITHUB_REPO,
  milestone: 8, # Verison 1.1 is 8. Icebox is 6.
  state: 'open',
  per_page: 100, # 100 is max.
  labels: 'Bug', # 'Story', 'Request', 'Bug', 'High', 'Critical'
  sort: 'created', # 'created', 'updated', 'comments'
  direction: 'asc' # 'asc', 'desc'. 'Ascending' because we want newest ones prioritized first in Pivotal.
  # assignee: '*',
  # mentioned: 'octocat',
)

# Get a single issue:
#issue = github.issues.find(GITHUB_USER, GITHUB_REPO, 301)
# Careful when getting a single issue. The signature of the objects
# returned is different than when iterating issues.list_repo().
# IOW, some stuff below breaks.

PivotalTracker::Client.token = PIVOTAL_TOKEN
proj = PivotalTracker::Project.find(PIVOTAL_PROJECT_ID)

# 100 per page is max, so we can iterate all pages like this:
# issues.each_page do |page|
#   page.each do |issue|
#     p issue.id
#   end
# end
# But paging like that causes it to not pay attention to
# any filering above in the list_repo() method options.
# So we have to break thing up into sub-100 chunks.

i = 0
issues.each_with_index do |issue|
  puts '*************************************************'
  puts '*** MIGRATING GITHUB ISSUE to PIVOTAL TRACKER ***'
  puts 'Owner:       ' + issue.user.login
  puts 'Assigned to: ' + issue.assignee.login if issue.assignee
  puts 'Date:        ' + issue.created_at
  puts 'Story:       ' + issue.title
  puts '*************************************************'
  puts issue.body

  # # Create story in Pivotal Tracker
  story = proj.stories.create(
    name: issue.title,
    description: issue.body,
    created_at: issue.created_at,
    # labels: 'Request',
    # owned_by: issue.assignee.login,
    # requested_by: issue.user.login,
    story_type: 'bug', # 'bug', 'feature', 'chore', 'release'. Omitting makes it a feature.
    current_state: 'unstarted' # 'unstarted', 'started', 'accepted', 'delivered', 'finished', 'unscheduled'.
    # Omitting puts it in the Icebox.
    # 'unstarted' puts it in 'Current' if Commit Mode is on; 'Backlog' if Auto Mode is on.
  )

  comments = github.issues.comments.all 'telvue', 'Connect', issue.number
  comments.each do |comment|
    puts '--------------'
    puts 'ADDING COMMENT'
    puts 'From: ' + comment.user.login
    puts 'Date: ' + comment.created_at
    puts ''
    puts comment.body

    story.notes.create(
      text: comment.body.gsub(/\r\n\r\n/, "\n\n"),
      author: comment.user.login,
      noted_at: comment.created_at
    )
  end
  i = i + 1
end
puts '=============='
puts 'TOTAL MIGRATED: ' + i.to_s
puts '=============='