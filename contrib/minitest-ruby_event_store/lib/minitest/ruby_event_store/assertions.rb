require 'byebug'
module Minitest
  module RubyEventStore
    module Assertions
      def assert_dispatched(event_store, expected_events, &block)
        collected_events = collect_events(event_store, &block)

        Array(expected_events).each do |expected|
          assert collected_events.map(&:event_type).include?(expected.to_s), <<~EOM
            Expected 
              #{collected_events}
            to include 
              #{expected}
          EOM
        end
      end

      def assert_not_dispatched(event_store, expected_events, &block)
        collected_events = collect_events(event_store, &block)

        Array(expected_events).each do |expected|
          refute collected_events.map(&:event_type).include?(expected.to_s), <<~EOM
            Expected 
              #{collected_events}
            to NOT include 
              #{expected}
          EOM
        end
      end

      def assert_not_published(event_store, event_type, stream = nil, &block)
        assert_equal 0, events_published(event_store, event_type, stream, &block).size, "Expected no event of #{event_type} type"
      end

      def assert_published(event_store, event_type, event_data, stream = nil, &block)
        events = events_published(event_store, event_type, stream, &block)
        refute events.empty?, "Expected some events of #{event_type} type, none were there"
        events.each do |e|
          assert_equal event_data.with_indifferent_access, e.data, "Event data mismatch"
        end
      end

      def assert_published_once(event_store, event_type, event_data, stream = nil, &block)
        events = assert_published(event_store, event_type, event_data, stream, &block)
        assert_equal 1, events.size, "Expected only one event of #{event_type} type"
      end

      def assert_nothing_published(event_store, &block)
        assert_equal 0,
                     events_published(event_store, nil, nil, &block).size,
                     "Expected no events published"
      end

      private

      def events_published(event_store, event_type, stream, &block)
        query = event_store.read
        query = query.stream(stream) if stream
        query = query.of_type(event_type) if event_type
        if block
          events_before = query.to_a
          block.call
        else
          events_before = []
        end
        events_after = query.to_a
        events_after - events_before
      end

      def collect_events(event_store, &block)
        collected_events = []
        event_store.within { block.call }.subscribe_to_all_events { |event| collected_events << event }.call
        collected_events
      end
    end
  end
end
