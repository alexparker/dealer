defmodule Dealer.ReviewParser do
  @moduledoc """
  Helper functions for parsing the html

  When the website markup changes, this is where we would update things
  """
  @type floki_entry() :: Floki.html_tree()

  @spec get_entries!(binary) ::
          :error
          | [
              {:comment, binary}
              | {:pi | binary, binary | [{any, any}], [binary | {any, any} | {any, any, any}]}
              | {:doctype, binary, binary, binary}
            ]
  def get_entries!(html) do
    html
    |> Floki.parse_document()
    |> case do
      {:ok, document} ->
        document
        |> Floki.find(".review-entry")

      {:error, _reason} ->
        :error
    end
  end

  @spec get_employees(floki_entry()) :: [binary()]
  def get_employees(floki_entry) do
    floki_entry
    |> Floki.find(".tagged-emp")
    |> Enum.map(fn employee_node ->
      employee_node
      |> Floki.text()
      |> String.trim()
    end)
  end

  @spec get_stars(floki_entry()) :: integer
  @doc """
  Gets the first .rating-static class and parses from the class string: `rating-50`
  """
  def get_stars(floki_entry) do
    stars_class =
      floki_entry
      |> Floki.find(".rating-static")
      |> List.first()
      |> Floki.attribute("class")
      |> List.first()

    Regex.named_captures(~r/rating-(?<stars>[0-9]{2})/, stars_class)
    |> case do
      %{"stars" => stars} ->
        # Just going with the integer score. Maybe change later based on preference
        stars
        |> Decimal.new()
        |> Decimal.to_integer()

      nil ->
        0
    end
  end

  @spec get_text(floki_entry()) :: binary()
  def get_text(floki_entry) do
    floki_entry
    |> Floki.find(".review-content")
    |> Floki.text()
  end

  @spec get_author(floki_entry()) :: binary()
  def get_author(floki_entry) do
    floki_entry
    |> Floki.find(".review-wrapper h3 + .notranslate")
    |> Floki.text()
    |> String.trim("- ")
  end
end
