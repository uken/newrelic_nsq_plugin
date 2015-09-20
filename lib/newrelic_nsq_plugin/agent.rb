require 'newrelic_plugin'
require 'faraday'

module NewrelicNsqPlugin
  class Agent < ::NewRelic::Plugin::Agent::Base
    agent_guid 'com.uken.nsq'
    agent_version VERSION
    agent_human_labels('NSQ') { "#{name}" }
    agent_config_options :nsqd, :name

    def setup_metrics
    end

    def poll_cycle
      resp = http_client.get('/stats?format=json')

      if resp.status != 200
        puts('Failed to retrieve stats. Skipping...')
        return
      end

      report_from_stats(JSON.parse(resp.body))
    end

    private

    def report_from_stats(stats)
      data = stats.fetch('data')
      topics = data.fetch('topics')

      topics.each do |topic|
        report_topic(topic)
      end
    rescue => e
      puts("Failed to report stats: #{e}")
    end

    def report_topic(data)
      topic_name = data.fetch('topic_name')
      depth = data.fetch('depth')
      message_count = data.fetch('message_count')
      channels = data.fetch('channels', [])


      report_metric "Topic/Depth/#{topic_name}", 'messages', depth
      report_metric "Topic/Count/#{topic_name}", 'messages', message_count

      channels.each do |channel|
        report_channel(topic_name, channel)
      end
    end

    def report_channel(topic_name, data)
      channel_name = data.fetch('channel_name')
      depth = data.fetch('depth')
      message_count = data.fetch('message_count')
      in_flight = data.fetch('in_flight_count')
      deferred_count = data.fetch('deferred_count')
      requeue_count = data.fetch('requeue_count')
      timeout_count = data.fetch('timeout_count')

      report_metric "Channel/Depth/#{topic_name} - #{channel_name}", 'messages', depth
      report_metric "Channel/Count/#{topic_name} - #{channel_name}", 'messages', message_count
      report_metric "Channel/In Flight/#{topic_name} - #{channel_name}", 'messages', in_flight
      report_metric "Channel/Deferred/#{topic_name} - #{channel_name}", 'messages', deferred_count
      report_metric "Channel/Requeued/#{topic_name} - #{channel_name}", 'messages', requeue_count
      report_metric "Channel/Timed Out/#{topic_name} - #{channel_name}", 'messages', timeout_count
    end

    def http_client
      Faraday.new(url: "http://#{nsqd}") do |cfg|
        cfg.adapter  Faraday.default_adapter
      end
    end
  end
  NewRelic::Plugin::Setup.install_agent :nsq, NewrelicNsqPlugin
end
