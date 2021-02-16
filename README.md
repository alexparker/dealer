# Dealer

Scrapes reviews from a given dealer page at deallerrater.com

Provided the url of the first page, and the number of pages, `Dealer` will pull and rank them based on a score of optimism.

Those pesky optimists must be stopped.

## Set Up
```bash
git clone git@github.com:alexparker/dealer.git
cd dealer
mix deps.get
```

## Usage
Basic usage examples

**With IEx**
```bash
$ iex -S mix
iex(1)> Dealer.fetch("https://www.dealerrater.com/dealer/McKaig-Chevrolet-Buick-A-Dealer-For-The-People-dealer-reviews-23685", 5, 3)
```

**Mix task**

Defaults to 5 pages and top 3 optimistic reviews
```bash
$ mix dealer.for_the_people
```

## Result
```bash
[
  %{
    employee_factor: 9,
    optimism: 63,
    positive_words: ["friendly", "great"],
    rating_data: %{
      author: "donnieb6680",
      employees: ["Taylor Prickett", "Shonna Stuve", "David Varner",
       "Alisa Cerney", "Summur Villareal", "Mark Abernathy", "Susie Scadden",
       "Lisa Bryant"],
      stars: 50,
      text: "Dealing with McKaig in Gladewater is 100% better than any other experience at other dealerships.  They worked hard to learn exactly what kind of car and price I was trying to get, and they helped me find a deal to fit my needs.  I didn't feel pressured like some of the other dealerships.  \r\nI connected first with Summer and Alisa online via the website and then worked with David once I got to the dealership.  They were all very friendly and helpful.  Taylor also did a great job of explaining all the financing terms. \r\n\r\n10/10 would definitely recommend them all! "
    }
  },
  %{
    employee_factor: 10,
    optimism: 63,
    positive_words: ["love"],
    rating_data: %{
      author: "Gabrielled1992",
      employees: ["Kent Abernathy", "Adrian \"AyyDee\" Cortes", "Eric Goodes",
       "Mike Lambert", "Taylor Prickett", "Dennis Smith", "Shonna Stuve",
       "Freddie Tomlinson", "David Varner"],
      stars: 50,
      text: "Mckaig is the dealership for the people. Thanks you Eric Goodess and the entire Mckaig staff for such an amazing job . I love my Buick Encore "
    }
  },
  %{
    employee_factor: 2,
    optimism: 61,
    positive_words: ["best", "comfortable", "great", "love"],
    rating_data: %{
      author: "Tasha",
      employees: ["Adrian \"AyyDee\" Cortes"],
      stars: 50,
      text: "Great customer service! I felt very comfortable with Adrian. He was very patient and never pushy during the process. I appreciate his willingness to go above and beyond to help me achieve the best deal possible. I love my new ride!"
    }
  }
]
```