# README

Ruby 3.0.2

Postgres

Run: `rails s`
Debug: `rdbg bin/rails s`

## Routes

`localhost:3000/filer` will get you a list of all the filers stored in the database
`localhost:3000/receiver?state=[2 letter state code, eg MA]` will get you a list of the receivers for a given state.

Or, you can take a look on Heroku, here:
https://boiling-coast-34554.herokuapp.com/filer

## Entity relations

A filer has many awards, an award has 1 receiver. 

