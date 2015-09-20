require 'newrelic_plugin'
require 'faraday'

module NewrelicNsqPlugin
  class Agent < ::NewRelic::Plugin::Agent::Base
    agent_guid 'com.uken.nsq'
    agent_version VERSION
    agent_human_labels('NSQ') { "#{name}" }
    agent_config_options :nsqd, :name

    def setup_metrics
      @epochs = Hash.new { |h, k| h[k] = NewRelic::Processor::EpochCounter.new }
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


      report_metric "Topic/Depth/#{topic_name}", 'Messages', depth
      report_epoch "Topic/Count/#{topic_name}", 'Messages/seconds', message_count

      channels.each do |channel|
        report_channel(topic_name, channel)
      end
    end

    def report_epoch(name, unit, value)
      processed_value = @epochs[name].process(value)
      report_metric(name, unit, processed_value)
    end

    def report_channel(topic_name, data)
      channel_name = data.fetch('channel_name')
      depth = data.fetch('depth')
      message_count = data.fetch('message_count')
      in_flight = data.fetch('in_flight_count')
      deferred_count = data.fetch('deferred_count')
      requeue_count = data.fetch('requeue_count')
      timeout_count = data.fetch('timeout_count')

      metric_name = "#{topic_name} - #{channel_name}"

      report_metric "Channel/Depth/#{metric_name}", 'Messages', depth
      report_epoch "Channel/Count/#{metric_name}", 'Messages/seconds', message_count
      report_metric "Channel/In Flight/#{metric_name}", 'Messages', in_flight
      report_metric "Channel/Deferred/#{metric_name}", 'Messages', deferred_count
      report_epoch "Channel/Requeued/#{metric_name}", 'Messages/seconds', requeue_count
      report_epoch "Channel/Timed Out/#{metric_name}", 'Messages/seconds', timeout_count
    end

    def http_client
      Faraday.new(url: "http://#{nsqd}") do |cfg|
        cfg.adapter  Faraday.default_adapter
      end
    end
  end
  NewRelic::Plugin::Setup.install_agent :nsq, NewrelicNsqPlugin
end
