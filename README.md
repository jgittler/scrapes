# scrapes

## Install
Clone Repo

`bundle install`

## Run

`bundle exec pry`
`require_relative "scrape file name"`
### IGG

`IGGScrape.js_script`
Run js scripts to get data to set variables in pry

`IGGScrape.new(sites, money, camps, file_name).download`
csv if file name should have data
### KS

`KSScrape.js_script`
Run js scripts to get data to set variables in pry

`KSScrape.new(urls, file_name).download`
csv if file name should have data
