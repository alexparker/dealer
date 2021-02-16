defmodule Mix.Tasks.Dealer do
  @moduledoc """
  Fetches dealer ratings from dealerrater.com
  Calculates an optimism score for them using the `Dealer` module and returns the top results
  """
  @shortdoc "Fetches top 3 results from a dealer base url on dealerrater.com"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    # This will start our application
    Mix.Task.run("app.start")
    url = List.first(args)
    Dealer.fetch(url, 5, 3)
  end

  defmodule ForThePeople do
    @moduledoc "Fetches top optimistic results for A Dealer for The People"
    @shortdoc "Fetches top 3 results from McKaig Chevrolet A Dealer For The People"
    use Mix.Task

    @impl Mix.Task
    def run(_args) do
      Mix.Task.run("app.start")

      Dealer.fetch(
        "https://www.dealerrater.com/dealer/McKaig-Chevrolet-Buick-A-Dealer-For-The-People-dealer-reviews-23685/",
        5,
        3
      )
      |> IO.inspect()
    end
  end
end
