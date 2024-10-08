defmodule DotfernoWeb.DemoLive do
  use Phoenix.LiveView, layout: {DotfernoWeb.Layouts, :app}
  import Dotferno.Format
  alias Dotferno.Aggregator
  alias Phoenix.PubSub
  import Dotferno.Format

  @impl true
  def mount(_params, _session, socket) do
    buckets_today = Aggregator.buckets_today()
    buckets_year = Aggregator.buckets_year()

    socket = update_state(%{buckets_today: buckets_today}, socket)
    socket = update_state(%{buckets_year: buckets_year}, socket)

    socket =
      assign(socket,
        biggest_today: Aggregator.biggest_today(),
        biggest_week: Aggregator.biggest_week()
      )

    socket = assign(socket, dark_mode_hook: "dark-mode")

    PubSub.subscribe(Dotferno.PubSub, "buckets")
    PubSub.subscribe(Dotferno.PubSub, "biggest")

    {:ok, socket}
  end

  @impl true
  def handle_info(%{buckets_today: _} = e, socket) do
    socket = update_state(e, socket)

    send_update(DotfernoWeb.Components.ChartComponent,
      id: :chart_today,
      event: "update_chart",
      y: socket.assigns.buckets_today,
      x: socket.assigns.timings_today
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{buckets_year: _} = e, socket) do
    socket = update_state(e, socket)

    send_update(DotfernoWeb.Components.ChartComponent,
      id: :chart_year,
      event: "update_chart",
      y: socket.assigns.buckets_year,
      x: socket.assigns.timings_year
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{biggest_today: _, biggest_week: _} = e, socket) do
    {:noreply, assign(socket, e)}
  end

  @impl true
  def handle_info(%{event: "new_burn"}, socket) do
    buckets_today = Aggregator.buckets_today()
    buckets_year = Aggregator.buckets_year()

    socket = update_state(%{buckets_today: buckets_today}, socket)
    socket = update_state(%{buckets_year: buckets_year}, socket)

    send_update(DotfernoWeb.Components.ChartComponent,
      id: :chart_today,
      event: "update_chart",
      y: socket.assigns.buckets_today,
      x: socket.assigns.timings_today
    )

    send_update(DotfernoWeb.Components.ChartComponent,
      id: :chart_year,
      event: "update_chart",
      y: socket.assigns.buckets_year,
      x: socket.assigns.timings_year
    )

    {:noreply, socket}
  end

  def update_state(%{buckets_today: {buckets_today, timings}}, socket) do
    buckets_today = buckets_today |> Enum.map(fn x -> Dotferno.Format.plank_to_dot(x) end)
    sum_today = Enum.sum(buckets_today) |> Kernel.round()

    assign(socket,
      buckets_today: buckets_today,
      sum_today: sum_today,
      timings_today: render_timings(timings)
    )
  end

  def update_state(%{buckets_year: {buckets_year, timings}}, socket) do
    buckets_year = buckets_year |> Enum.map(fn x -> Dotferno.Format.plank_to_dot(x) end)
    sum_year = Enum.sum(buckets_year) |> Kernel.round()

    assign(socket,
      buckets_year: buckets_year,
      sum_year: sum_year,
      timings_year: render_dates(timings)
    )
  end

  def render_timings(timings) do
    Enum.map(timings, fn t -> t |> DateTime.truncate(:second) |> DateTime.to_iso8601() end)
  end

  def render_dates(timings) do
    Enum.map(timings, fn t -> t |> DateTime.to_date() |> Date.to_iso8601() end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-wrap">
      <div class="flex flex-col xs:flex-row justify-center md:justify-between w-full">
        <div class="flex justify-end">
          <div class="p-4">
            <div class="flex font-semibold rounded-lg items-center flex-col border glow py-6 px-6 bg-white dark:bg-gray-900 antialiased dark:border-gray-900">
              <div class="text-xs sm:text-sm md:text-base lg:text-lg xl:text-xl">
                24 hrs
              </div>
              <div class="text-lg text-center sm:text-left font-medium text-[#E6007A]">
                <%= fmt_dot(@sum_today) %>
              </div>
            </div>
          </div>

          <div class="p-4">
            <div class="flex font-semibold rounded-lg items-center flex-col border glow py-6 px-6 bg-white dark:bg-gray-900 antialiased dark:border-gray-900">
              <div class="text-xs sm:text-sm md:text-base lg:text-lg xl:text-xl">
                7 days
              </div>
              <div class="text-lg text-center sm:text-left font-medium text-[#E6007A]">
                <%= fmt_dot(@sum_year) %>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="p-4 w-full">
        <div class="flex rounded-lg h-full flex-col">
          <div class="flex items-center mb-5">
            <h2 class="text-lg sm:text-xl md:text-2xl font-bold text-center md:text-left w-full text-gray-900 dark:text-gray-100 tracking-tight leading-tight pb-2">
              Burns per hour (24 hrs)
            </h2>
          </div>
          <div class="text-gray-900 dark:text-white">
            <.live_component
              module={DotfernoWeb.Components.ChartComponent}
              id={:chart_today}
              y={@buckets_today}
              x={@timings_today}
              type="bar"
            />
          </div>
        </div>
      </div>

      <div class="flex flex-col xs:flex-row xs:justify-center md:justify-start w-full">
        <div class="p-4 w-full xs:w-1/2 md:w-auto">
          <div class="flex items-center mb-3">
            <h2 class="text-lg font-semibold text-center md:text-left w-full">
              Top today
            </h2>
          </div>
          <div class="flex rounded-lg items-center flex-col border glow bg-white dark:bg-gray-900 antialiased dark:border-gray-900">
            <ul class="max-w-md divide-y">
              <%= for v <- Enum.take(@biggest_today, 3) do %>
                <.link href={link_block(v.blockNumber)} target="_blank">
                  <li class="p-3">
                    <div class="flex items-center space-x-4 rtl:space-x-reverse text-[#E6007A]">
                      <div class="flex-1 items-center text-sm font-semibold">
                        <%= fmt_plank(v.amount) %>
                      </div>
                      <div class="inline-flex min-w-0">
                        <p class="text-sm font-medium truncate">
                          <%= fmt_time_ago(v.timestamp) %>
                        </p>
                      </div>
                    </div>
                  </li>
                </.link>
              <% end %>
            </ul>
          </div>
        </div>
        <div class="p-4 w-full xs:w-1/2 md:w-auto">
          <div class="flex items-center md:items-left mb-3">
            <h2 class="text-lg font-semibold text-center md:text-left w-full md:w-auto text-gray-900 dark:text-white">
              Top this week
            </h2>
          </div>
          <div class="flex rounded-lg items-center flex-col border glow bg-white dark:bg-gray-900 antialiased dark:border-gray-900">
            <ul class="max-w-md divide-y">
              <%= for v <- Enum.take(@biggest_week, 3) do %>
                <.link href={link_block(v.blockNumber)} target="_blank">
                  <li class="p-3">
                    <div class="flex items-center space-x-4 rtl:space-x-reverse text-[#E6007A]">
                      <div class="flex-1 items-center text-sm font-semibold">
                        <%= fmt_plank(v.amount) %>
                      </div>
                      <div class="inline-flex min-w-0">
                        <p class="text-sm font-medium truncate">
                          <%= fmt_time_ago(v.timestamp) %>
                        </p>
                      </div>
                    </div>
                  </li>
                </.link>
              <% end %>
            </ul>
          </div>
        </div>
      </div>

      <div class="p-4 w-full">
        <div class="flex rounded-lg h-full flex-col">
          <div class="flex items-center mb-5">
            <h2 class="text-lg sm:text-xl md:text-2xl font-bold text-center md:text-left w-full text-gray-900 dark:text-gray-100 tracking-tight leading-tight pb-2">
              Burns per day (7 days)
            </h2>
          </div>
          <div class="text-gray-900 dark:text-white">
            <.live_component
              module={DotfernoWeb.Components.ChartComponent}
              id={:chart_year}
              y={@buckets_year}
              x={@timings_year}
              type="bar"
            />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
