## open access figures auto-converted to slides

a proof of concept for reusing the scientific literature at scale.

The `getfigures` CLI tool takes a query which it runs against EuropePMC. It takes the results and generates a slidewinder slide with rich metadata for each figure in each paper.

Some example slides are included in the `data` directory.

## screenshot

![](https://raw.githubusercontent.com/slidewinder/open_access_figures/master/data/screenshot.png)

## usage

You'll need Node.js installed. Read our [guide to going this if you don't have it](http://www.slidewinder.io/docs/how_to_help/code/01_setting_up.html#installing-node-js).

clone this repository, then..

```
cd open_access_figures
npm install
```

this should install all dependencies

now you can run `getfigures`:

```
bin/getfigures.js
```

## example

```
bin/getfigures --query tardigrades --outdir tardigrades
```
