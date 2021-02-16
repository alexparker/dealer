defmodule Dealer do
  @moduledoc """
  Documentation for `Dealer`

  Use this module to read review ratings from dealerrater.com and extract info from their reviews.

  There is a `@word_scores` map of words and their optimistic value.
  In future versions this word bank will use a sentiment analysis API that has
  an actively trained data model to constantly improve the analysis of these reviews.

  Be vigilant in fighting optimism.
  """
  alias Dealer.ReviewParser

  @word_scores %{
    "love" => 3,
    "best" => 3,
    "awesome" => 3,
    "great" => 2,
    "lucky" => 2,
    "friendly" => 2,
    "comfortable" => 1,
    "good" => 1
  }

  @typedoc """
  Map structure for raw rating_data that is extracted from reviews
  """
  @type rating_data :: %{
          stars: integer(),
          employees: list(),
          text: String.t(),
          author: String.t()
        }

  @typedoc """
  Map structure for computed rating scores, storing the rating_data
  for output after computation
  """
  @type rating_score :: %{
          optimism: number(),
          positive_words: Enum.t(),
          employee_factor: number(),
          rating_data: rating_data() | nil
        }

  @doc """
  Returns the 3 most optimistic reviews

  Provide the url of the first page, and the number of pages to search
  """
  @spec fetch(binary, integer, integer) :: Enum.t()
  def fetch(dealer_url, pages_count \\ 5, reviews_count \\ 3)

  def fetch(dealer_url, pages_count, reviews_count) do
    dealer_url
    |> base_url()
    |> scrape_pages(pages_count)
    |> sort_by_optimism()
    |> Enum.slice(0..(reviews_count - 1))
  end

  @doc """
  This method asychrnously makes the request to the range of pages

  Then calls `Dealer.scrape_page/1` on each document to read and aggregate the reviews
  """
  @spec scrape_pages(binary(), integer()) :: Enum.t()
  def scrape_pages(dealer_base_url, pages_count) do
    page_urls =
      1..pages_count
      |> Enum.map(&"#{dealer_base_url}page#{&1}")

    stream =
      page_urls
      |> Stream.map(fn page_url ->
        Task.async(fn ->
          %HTTPoison.Response{
            status_code: status,
            body: body
          } = HTTPoison.get!(page_url)

          if status == 200 do
            scrape_page(body)
          else
            []
          end
        end)
      end)
      |> Stream.flat_map(&Task.await/1)

    stream
    |> Enum.to_list()
  end

  @doc """
  Takes the html document of a single page as a string for its only argument

  Uses `ReviewParser.get_entries!/1` to fetch the entries raw
  data as `Floki.html_tree()` list then runs the entries through
  `Dealer.read_and_score_entries/1` to map their data and compute their optimism scores
  """
  @spec scrape_page(binary()) :: list()
  def scrape_page(html) do
    html
    |> ReviewParser.get_entries!()
    |> read_and_score_entries()
  end

  @doc """
  Reads the parts of the review to extract data
  Using `Dealer.ReviewParser` methods it finds the sections
  in the `Floki.html_tag()` from the list
  """
  @spec read_and_score_entries(list()) :: Enum.t()
  def read_and_score_entries([]), do: []

  def read_and_score_entries(entries) do
    entries
    |> Enum.map(fn entry_node ->
      %{
        employees: ReviewParser.get_employees(entry_node),
        stars: ReviewParser.get_stars(entry_node),
        text: ReviewParser.get_text(entry_node),
        author: ReviewParser.get_author(entry_node)
      }
      |> score_optimism()
    end)
  end

  @doc """
  Simple sorting mechanism to sort each entry by `:optimism` score
  """
  @spec sort_by_optimism(Enum.t()) :: Enum.t()
  def sort_by_optimism(rating_scores) do
    rating_scores
    |> Enum.sort_by(& &1.optimism, :desc)
  end

  @doc """
  Returns a map of score data for the rating data passed in

  Be sure and include the rating data according to rating_data()
  """
  @spec score_optimism(rating_data()) :: rating_score()
  def score_optimism(rating_data) do
    %{
      optimism: 0.0,
      positive_words: [],
      employee_factor: 0.0,
      rating_data: rating_data
    }
    |> score_stars(rating_data)
    |> score_words(rating_data)
    |> score_employees(rating_data)
  end

  @doc """
  Counts the occurances of words in @word_scores
  Then multiplies the occurances by the optimistic value in @word_scores
  """
  @spec score_words(rating_score(), rating_data()) :: rating_score()
  def score_words(rating_score, rating_data) do
    positive_word_map =
      rating_data.text
      |> String.downcase()
      |> String.split()
      |> strip_special_chars()
      |> count_positive_words()

    positive_word_score =
      positive_word_map
      |> Enum.reduce(0, fn {word, count}, acc ->
        @word_scores[word] * count + acc
      end)

    rating_score
    |> Map.put(:positive_words, Map.keys(positive_word_map))
    |> Map.put(:optimism, rating_score.optimism + positive_word_score)
  end

  @doc """
  Adds to the optimism score by summing total employee interaction
  in the review with the optimism score
  """
  @spec score_employees(rating_score(), rating_data()) :: rating_score()
  def score_employees(rating_score, rating_data) do
    employee_interaction = 1 + length(rating_data.employees)

    rating_score
    |> Map.put(:optimism, rating_score.optimism + employee_interaction)
    |> Map.put(:employee_factor, employee_interaction)
  end

  # Starts the optimism score off with the base star score as an integer
  # Where 48 represents a 4.8 star display
  @spec score_stars(rating_score(), rating_data()) :: rating_score()
  defp score_stars(rating_score, rating_data) do
    rating_score
    |> Map.put(:optimism, rating_data.stars)
  end

  # Stripping special characters from the words parsed in the review text
  @spec strip_special_chars(list()) :: list()
  defp strip_special_chars([]), do: []

  defp strip_special_chars([head | tail]) do
    (Regex.run(~r/\w+/, head) || []) ++ strip_special_chars(tail)
  end

  # Counting positive words occurances
  @spec count_positive_words(list()) :: %{String.t() => integer()}
  defp count_positive_words(words) do
    positive_words = Map.keys(@word_scores)

    Enum.reduce(words, %{}, fn word, map ->
      # Only count if in positive word list
      if Enum.member?(positive_words, word) do
        Map.put(map, word, (map[word] || 0) + 1)
      else
        map
      end
    end)
  end

  # Base Url helper to make testing easier
  defp base_url(url_string) do
    if Mix.env() == :test do
      url_string
    else
      # Append single trailing slash whether or not its present
      String.trim_trailing(url_string, "/") <> "/"
    end
  end
end
