#!/usr/bin/env ruby

# Description:  Migrates GitHub Issues to Pivotal Tracker.

GITHUB_ORG = 'APX'
GITHUB_USER = 'shyam-habarakada'
GITHUB_REPO = 'APX/benchpress-server'
GITHUB_LOGIN = 'shyam-habarakada'
PIVOTAL_PROJECT_ID = '836893'

GITHUB_PASSWORD = ENV['GITHUB_PASSWORD']
PIVOTAL_TOKEN = ENV['PIVOTAL_TOKEN']

require 'rubygems'
require 'octokit'
require 'pivotal-tracker'

puts ENV['GITHUB_PASSWORD']
puts ENV['PIVOTAL_TOKEN']

PivotalTracker::Client.token = PIVOTAL_TOKEN

total_issues = 0 # how many issues were processed?

github = Octokit::Client.new(:login => GITHUB_LOGIN, :password => GITHUB_PASSWORD)

issues_filter = 'bug'

page_issues = 1
issues = github.list_issues(GITHUB_REPO, { :page => page_issues, :labels => issues_filter } )

while issues.count > 0

  issues.each do |issue|
    total_issues += 1
    comments = github.issue_comments(GITHUB_REPO, issue.number)
    puts "issue: #{issue.number} #{issue.title}, with #{comments.count} comments"

    comments.each do |comment|
      puts "  #{comment.body} (#{comment.user.login})"
    end

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
    
    # comments = github.issues.comments.list GITHUB_ORG, GITHUB_REPO, :issue_id => issue.number
    # comments.each_page do |comments_page|
    #   comments_page.each do |comment|
    #     puts "  comment: #{comment.body}"
    #     story.notes.create(
    #       text: comment.body.gsub(/\r\n\r\n/, "\n\n"),
    #       author: comment.user.login,
    #       noted_at: comment.created_at
    #     )
    #   end
    # end

  end

  page_issues += 1
  issues = github.list_issues(GITHUB_REPO, { :page => page_issues, :labels => issues_filter } )

end

puts "\n== processed #{total_issues} issues"
