## open access figures auto-converted to slides

a proof of concept for reusing the scientific literature at scale.

The `getfigures` CLI tool takes a query which it runs against EuropePMC. It takes the results and generates a slidewinder slide with rich metadata for each figure in each paper.

Some example slides are included in the `data` directory.

## screenshot

![](https://www.dropbox.com/s/qxf3xug3i9tbvew/Screenshot%202016-01-17%2015.31.44.png?dl=1])

## usage

clone the repository

then:

- `npm install`
- `bin/getfigures --help`

## example

```
bin/getfigures --query tardigrades --outdir tardigrades
```
