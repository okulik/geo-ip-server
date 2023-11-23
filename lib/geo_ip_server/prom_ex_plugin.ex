defmodule GeoIpServer.PromExPlugin do
  @moduledoc """
  Used for exporting custom metrics to Prometheus.
  """

  use PromEx.Plugin

  @csv_import_duration_event [:geo_ip_server, :csv_import, :duration]
  @csv_import_duration_event_buckets [100_000, 200_000, 500_000, 1_000_000]

  @impl true
  def event_metrics(_opts) do
    [
      # Create custom Prometheus metrics
      Event.build(
        :geo_ip_server_csv_import_duration_event_metrics,
        [
          distribution(
            @csv_import_duration_event,
            event_name: @csv_import_duration_event,
            description: "The duration in milliseconds of CSV import.",
            measurement: :took,
            unit: {:native, :nanosecond},
            tags: [:csv],
            tag_values: &get_csv_file_name/1,
            reporter_options: [buckets: @csv_import_duration_event_buckets]
          )
        ]
      )
    ]
  end

  def csv_import_duration_event_buckets do
    @csv_import_duration_event_buckets
  end

  defp get_csv_file_name(%{csv: csv_file_name}) do
    %{csv: csv_file_name}
  end
end
