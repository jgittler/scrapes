# scrapes

## Install
Clone Repo

`bundle install`

## Run

`bundle exec pry`
### IGG
`load "./igg_scrape.rb"`

`IGGScrape.js_script`
Run js scripts to get data to set variables in pry

`IGGScrape.new(sites, money, camps, file_name).download`
### KS
`load "./ks_scrape.rb"`

`KSScrape.js_script`
Run js scripts to get data to set variables in pry

`KSScrape.new(urls, file_name).download`
### Insta
`load "./insta_scrape.rb"`

`InstaScrape.js_script`
Run js scripts to get data to set variables in pry

`i = InstaScrape.new(names, file_name)`
To run requests

`i.collect_all`
To see success of run

`i.stats`
If you want to download all the users without filtering them down, run this now

`i.download`
Then you can rename the file name to for the next download

`i.file = "new_file.csv"`
To see how many user qualify based on your filters

`i.filtered_count`
Now you can change your filters and see how many qualify after tweaks. Can also run `i.stats` again.

Default filters are:
```
er_cut = 2.0
min_f = 10000
max_f = 80000
All can be set after initialization
```
### To clean csv from BuzzStream for YAMM
`load "./bs_to_y.rb"`

`BSToY.new(file_to_read, file_to_download).download`
