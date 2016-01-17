## open access figures auto-converted to slides

a proof of concept for reusing the scientific literature at scale.

The `getfigures` CLI tool takes a query which it runs against EuropePMC. It takes the results and generates a slidewinder slide with rich metadata for each figure in each paper.

Some example slides are included in the `data` directory.

## screenshot

![](https://raw.githubusercontent.com/slidewinder/open_access_figures/master/data/screenshot.png)

## usage

clone the repository

then:

- `npm install`
- `bin/getfigures --help`

## example

```
bin/getfigures --query tardigrades --outdir tardigrades
```
