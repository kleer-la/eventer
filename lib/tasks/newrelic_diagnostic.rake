namespace :newrelic do
  desc "Check New Relic configuration and status"
  task diagnostic: :environment do
    puts "=== New Relic Diagnostic Information ==="
    
    begin
      require 'newrelic_rpm'
      puts "✅ New Relic gem loaded successfully"
      
      # Check if agent is configured
      if defined?(NewRelic::Agent)
        puts "✅ New Relic Agent is defined"
        
        # Check configuration
        config = NewRelic::Agent.config
        puts "📋 Configuration:"
        puts "   License Key: #{config[:license_key] ? '[SET]' : '[NOT SET]'}"
        puts "   App Name: #{config[:app_name] || '[NOT SET]'}"
        puts "   Agent Enabled: #{config[:agent_enabled]}"
        puts "   Monitor Mode: #{config[:monitor_mode]}"
        puts "   Environment: #{Rails.env}"
        puts "   Error Collector Enabled: #{config[:'error_collector.enabled']}"
        puts "   Error Capture Source: #{config[:'error_collector.capture_source']}"
        
        # Check environment variables
        puts "\n🔧 Environment Variables:"
        puts "   NEW_RELIC_LICENSE_KEY: #{ENV['NEW_RELIC_LICENSE_KEY'] ? '[SET]' : '[NOT SET]'}"
        puts "   NEW_RELIC_APP_NAME: #{ENV['NEW_RELIC_APP_NAME'] || '[NOT SET]'}"
        
        # Agent status
        if NewRelic::Agent.agent.started?
          puts "✅ New Relic Agent is started and running"
        else
          puts "❌ New Relic Agent is NOT started"
        end
        
      else
        puts "❌ New Relic Agent is not defined"
      end
      
    rescue LoadError => e
      puts "❌ Failed to load New Relic: #{e.message}"
    rescue => e
      puts "❌ Error checking New Relic status: #{e.message}"
    end
    
    puts "\n💡 If you're seeing issues:"
    puts "   1. Make sure NEW_RELIC_LICENSE_KEY is set in Heroku"
    puts "   2. Check that the license key is valid"
    puts "   3. Verify the app is receiving traffic"
    puts "   4. Check New Relic logs in log/newrelic_agent.log"
    puts "   5. Restart the application after making changes"
  end
end