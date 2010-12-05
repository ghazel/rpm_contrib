if defined?(::Curl) and not NewRelic::Control.instance['disable_curb']
  Curl::Easy.class_eval do
    def host
      URI.parse(self.url).host
    end

    # TODO: http, http_delete, http_get, http_post, http_head, http_put
    def perform_with_newrelic_trace(*args, &block)
      metrics = ["External/#{host}/Curl::Easy","External/#{host}/all"]
      if NewRelic::Agent::Instrumentation::MetricFrame.recording_web_transaction?
        metrics << "External/allWeb"
      else
        metrics << "External/allOther"
      end
      self.class.trace_execution_scoped metrics do
        perform_without_newrelic_trace(*args, &block)
      end
    end
    alias perform_without_newrelic_trace perform
    alias perform perform_with_newrelic_trace
  end

  Curl::Multi.class_eval do
    # TODO: http
    def perform_with_newrelic_trace(*args, &block)
      metrics = ["External/Curl::Multi"]
      curl_metrics = Set.new
      requests.each do |curl|
        curl_metrics.add("External/#{curl.host}/Curl::Multi")
        curl_metrics.add("External/#{curl.host}/all")
      end
      metrics.concat curl_metrics.to_a
      if NewRelic::Agent::Instrumentation::MetricFrame.recording_web_transaction?
        metrics << "External/allWeb"
      else
        metrics << "External/allOther"
      end
      self.class.trace_execution_scoped metrics do
        perform_without_newrelic_trace(*args, &block)
      end
    end
    alias perform_without_newrelic_trace perform
    alias perform perform_with_newrelic_trace
  end
end
