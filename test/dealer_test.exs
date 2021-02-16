defmodule DealerTest do
  use ExUnit.Case
  import Mock
  doctest Dealer

  describe "score_words/2" do
    test "returns positive words" do
      review_score = %{
        optimism: 1,
        positive_words: [],
        employee_factor: 10
      }

      review_data = %{
        stars: 50,
        employees: [],
        # increasing optimism: awesome[3] + love[3] + great[2] = adds 8
        text: "awesome i love this company!!! Man, their service was great!!",
        author: "george"
      }

      assert %{
               optimism: 9,
               positive_words: positive_words,
               employee_factor: 10
             } = Dealer.score_words(review_score, review_data)

      assert length(positive_words) == 3
      assert Enum.member?(positive_words, "love")
      assert Enum.member?(positive_words, "great")
      assert Enum.member?(positive_words, "awesome")
    end
  end

  describe "score__employees" do
    test "adds employee interaction score to optimism" do
      review_score = %{
        optimism: 50,
        positive_words: [],
        employee_factor: 10
      }

      review_data = %{
        stars: 50,
        # increasing optimism: 1 + 4 employees
        employees: ["george", "sam", "jennifer", "crystal"],
        text: "No optimistic text",
        author: "george"
      }

      assert %{
               optimism: 55,
               employee_factor: 5
             } = Dealer.score_employees(review_score, review_data)
    end
  end

  describe "scrape_page/1" do
    test "fetches review data from a page" do
      reviews =
        "test/fixture.dealer-page.html.page1"
        |> File.read!()
        |> Dealer.scrape_page()

      assert length(reviews) == 10

      assert %{
               employee_factor: _factor,
               optimism: _optimism,
               positive_words: _positive_words,
               rating_data: %{
                 stars: 50,
                 employees: ["Adrian \"AyyDee\" Cortes"],
                 text:
                   "I walked in and immediately felt comfortable looking at the vehicles and talking to the dealer about working out a deal on a first time purchase.",
                 author: "raymundoalvarez18"
               }
             } = List.first(reviews)
    end
  end

  describe "sort_by_optimism" do
    test "sorts in descending order" do
      scores = [
        %{optimism: 10, text: "last"},
        %{optimism: 111, text: "first"},
        %{optimism: 59, text: "middle"}
      ]

      assert ["first", "middle", "last"] = Dealer.sort_by_optimism(scores) |> Enum.map(& &1.text)
    end
  end

  describe "scrape_pages/2" do
    test "renders the reviews for multiple pages" do
      with_mock(HTTPoison,
        get!: fn page_url ->
          %HTTPoison.Response{
            status_code: 200,
            headers: [],
            body: File.read!(page_url)
          }
        end
      ) do
        page_base_url = "test/fixture.dealer-page.html."

        reviews = Dealer.scrape_pages(page_base_url, 2)
        assert length(reviews) == 20
      end
    end
  end

  describe "fetch/3" do
    test "returns the top 3 optimistic reviews" do
      with_mock(HTTPoison,
        get!: fn page_url ->
          %HTTPoison.Response{
            status_code: 200,
            headers: [],
            body: File.read!(page_url)
          }
        end
      ) do
        page_base_url = "test/fixture.dealer-page.html."

        unsorted_reviews = Dealer.scrape_pages(page_base_url, 2)
        [top | _tail] = reviews = Dealer.fetch(page_base_url, 2, 3)
        assert length(reviews) == 3
        assert top == Enum.max_by(unsorted_reviews, & &1.optimism)
      end
    end
  end
end
