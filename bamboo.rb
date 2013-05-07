require 'sinatra'
require 'sinatra/config_file'
require 'bamboo-client'
require 'octokit'
require 'json'
require './patch.rb'

config_file 'config.yml'

before do
  # Bamboo Client
  begin
    @bamboo_client = Bamboo::Client.for(:rest, settings.bamboo['url'])
    @bamboo_client.login(settings.bamboo['username'], settings.bamboo['password'])
  rescue SocketError
    "Wrong Bamboo URL Address! Please check your configuration file."
  end

  # Github Client
	@github_client = Octokit::Client.new(:login => settings.github['username'], :oauth_token => settings.github['token'])
end

post '/build-plan/:key' do |key|
  begin
    plan = @bamboo_client.plan_for(key)
    if plan.enabled?

      # GitHub JSON Request
  		data = JSON.parse(request.body.read)

      # Get Pull Request Parameters
      pull_request = data['pull_request']
      if pull_request and pull_request['head']

        # Set Repository Full Name
        repository_full_name = pull_request['head']['repo']['full_name']

        # Trigger Build
        build_result = plan.queue({
          :'bamboo.variable.repositoryFullName' => repository_full_name,
          :'bamboo.variable.sha' => pull_request['head']['sha'],
        })

        puts "Build \##{build_result.data['buildNumber']} triggered"
      end
    else
      "This plan is not enabled in Bamboo database"
    end
  rescue RestClient::ResourceNotFound
  	"This plan does not exist in Bamboo database"
  end
end

get '/build-plan-status/:key' do |key|
  begin
    plan = @bamboo_client.plan_for(key)
    if plan.enabled?

      # Get Build Status
      plan_results = plan.results
      if plan_results
        latest = plan_results.first
        if latest.successful?
          build_state_image = "images/passing.png"
        else
          build_state_image = "images/failing.png"
        end
      else
        build_state_image = "images/unknown.png"
      end

      # Stream Build State Image
      content_type "image/png"
      return open(build_state_image, "rb") {|io| io.read }

    else
      "This plan is not enabled in Bamboo database"
    end
  rescue RestClient::ResourceNotFound
    "This plan does not exist in Bamboo database"
  end
end

get '/manage-hooks' do
  @repo_name = params[:repo_name]

  if @repo_name
    begin
  	  @hooks = @github_client.hooks(@repo_name)
    rescue Octokit::NotFound
  	  @message = "This repository is not found in GitHub (example: borislav-angelov/bamboo-pull-requests)"
  	end
  end

  erb :'manage-hooks'
end

post '/manage-hooks' do
  repo_name = params[:repo_name]
  hook_events = params[:hook_events]
  hook_url = params[:hook_url]
  hook_id = params[:hook_id]

  if repo_name and hook_id
  	@github_client.test_hook(repo_name, hook_id)

    redirect '/manage-hooks?repo_name=' + repo_name
  elsif repo_name and hook_events and hook_url
	  @github_client.create_hook(repo_name, 'web', {
      :url => hook_url,
      :content_type => 'json'
  	}, {
      :events => hook_events.split(','),
      :active => true
    })

    redirect '/manage-hooks?repo_name=' + repo_name
  end

  erb :'manage-hooks'
end

delete '/manage-hooks' do
	repo_name = params[:repo_name]
	hook_id = params[:hook_id]

	if repo_name and hook_id
	  @github_client.remove_hook(repo_name, hook_id)

	  redirect '/manage-hooks?repo_name=' + repo_name
	end
end

post '/update-status' do
  build_number = params[:build_number]
  build_results_url = params[:build_results_url]
  repo_name = params[:repo_name]
  sha = params[:sha]
  status = params[:status]

  # Update Status
  message = nil
  if status == "pending"
    message = "Build \##{build_number} started..."
  elsif status == "success"
    message = "Build \##{build_number} succeeded."
  else
    message = "Build \##{build_number} failed!"
  end

  @github_client.create_status(repo_name, sha, status, {:description => message, :target_url => build_results_url})

  puts "Build \##{build_number} status updated"
end

