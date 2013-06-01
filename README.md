# Genreator

I hate the standard genres that generally get put on my music files, so I wrote something to do a better job.

The idea is to use musicbrainz and wikipedia to generate a list of genres for each artist, then assign one of those to each. I want my genres to be very granular, so ideally, I want to assign the genre with the fewest artists in it (as long as it's more than 1).

Currently, it can read artists from files, and generate a list of genres with counts. It doesn't yet write back to the music files.

## Usage

You'll need Ruby 2.0.0 and taglib installed.

Then:

```
bundle
genreator.rb /path/to/music/files
```

The script stores a list of genres per artist in `artists.yml`, to avoid repeated lookups. Just remove the file to start from scratch.

## License

Open source under the MIT license; see LICENSE.md for details.