# getfigures
# download figures + captions from the open access literature
#
# getfigures does the following:
#
# 1. download XML and images for papers matching a search term using getpapers
# 2. extract the figure captions using beau-selector
# 3. map each caption to its image, and create a slidewinder slide
#
# getfigures only works with Open Access (OA) papers - the legal confusion
# surrounding non-OA works makes it too risky to use them.

pjson = require '../package.json'
path = require 'path'
child_process = require 'child_process'
exec = child_process.execSync
spawn = child_process.spawnSync
util = require 'util'

program = require 'commander'
yaml = require 'js-yaml'
progress = require 'progress'
fs = require 'fs-extra'
chalk = require 'chalk'

# ANSI Terminal Colors
bold = '\x1b[0;1m'
green = '\x1b[0;32m'
reset = '\x1b[0m'
red = '\x1b[0;31m'

(->@)().NBIN_DIR = path.join(__dirname, '..', 'node_modules', '.bin')
(->@)().DATA_DIR = path.join(__dirname, '..', 'data')

program
  .version(pjson.version)
  .option('--query <string>', 'query to select papers')
  .option('--outdir <string>', 'directory name (will be created under ./data)')
  .parse(process.argv)

# show help if there are no arguments
if process.argv.length < 3
  program.help()

if not ('query' of program) or not ('outdir' of program)
  console.log('You must provide both --query and --outdir')
  process.exit(1)

program.outdir = path.join(DATA_DIR, program.outdir)

# ## *log*
#
# **given** string as a message
# **and** string as a color
# **and** optional string as an explanation
# **then** builds a statement and logs to console.
#
log = (message, color, explanation) ->
  console.log color + message + reset + ' ' + (explanation or '')

# ## *launch*
#
# **given** string as a cmd
# **and** optional array and option flags
# **and** optional callback
# **then** spawn cmd with options
# **and** redirect child stdio to this process stdio to preserve colours
# **and** on child process exit emit callback if set and status is 0
launch = (cmd, options=[], callback) ->
  _cmd = path.join(NBIN_DIR, cmd)
  log('  running command:', green, [cmd].concat(options).join(' '))
  app = spawn(_cmd, options, { stdio: [0, 1, 2] })

  if app.status is 0
    callback?()
  else
    log('✗ command failed:', red, cmd)

# now we're ready to rock

# ## *getpapers*
#
# **given** string as query
# **and** string as a outdir
# **then** run getpapers to download papers matching query to outdir
getpapers = (query, outdir) ->
  launch('getpapers',
         ['--query',  query + ' AND (SRC:pmc OR SRC:med) AND IN_EPMC:y AND LICENSE:cc', '--outdir', outdir, '--xml'])

# ## *bo*
#
# *given* string as filepath
# **and** string as selector
# **and** optional string as attr
# **then** run bo on filepath to get selector[attr]
# **and** return the result
bo = (filepath, selector, attr) ->
  _bo = path.join(NBIN_DIR, 'bo')
  attropt = ''
  attropt = "--attribute '#{attr}' " if attr?
  tmpfile = "#{filepath}.tmp"
  cmd = "cat #{filepath} | #{_bo} \"#{selector}\" #{attropt}"
  try
    stdout = exec(cmd, { stdio: 'pipe' })
    return stdout.toString().split("\n")
  catch
    return []

# ## *select_figdata*
#
# **given** filepath
# **then** run beau-selector extract figure caption and metadata from xml
select_figdata = (datadir) ->
  fulltext = path.join(datadir, 'fulltext.xml')
  figdata =
    captions: bo(fulltext, "fig > caption")
    images: bo(fulltext, 'graphic', 'xlink:href')
  figdata

getIdentifier = (result) ->

  types = ['pmcid', 'doi', 'pmid', 'title'];
  for type in types
    if (type of result) and (result[type].length > 0)
      return {
        type: type
        id: result[type][0]
      }

  return {
    type: 'error'
    id: 'unknown ID'
  }

eupmc_img_urls = (article_id, figure_id) ->
  urls =
    thumb: "http://europepmc.org/articles/#{article_id}/bin/#{figure_id}.gif"
    full: "http://europepmc.org/articles/#{article_id}/bin/#{figure_id}.jpg"

frontmatter_from_eupmc_result = (result, thumb_url, i) ->
  metadata =
    name: "#{result.pmid}_fig#{i+1}"
    title: result.title?[0]
    authorString: result.authorString?[0]
    pmcid: result.pmcid?[0]
    pmid: result.pmid?[0]
    abstract: result.abstractText?[0]
    doi: result.DOI?[0]
    thumb_url: thumb_url
    figure_no: i + 1
    tags: ['eupmc', 'figure'].concat (result.keywordList?.keyword or [])
  try
    return yaml.safeDump(metadata)
  catch
    return false

cleanup_caption = (caption) ->
  return caption.replace(/\r?\n|\r/g, ' ')
    .replace(/<\/?p>/g, ' ')
    .replace(/<\/?(italic|em)>/g, '*')
    .replace(/<\/?(bold|strong)>/g, '**')
    .trim()

slide_from_fig = (caption, img, frontmatter, i) ->
  "---\n#{frontmatter}---\n" +
  "<img src='#{img}' style='max-height: 300px'>\n" +
  "### Figure #{i+1}\n" +
  "<p style='font-size: 10px;'>#{caption}</p>"

# now let's make the magic happen

p = program
try
  fs.accessSync(p.outdir, fs.F_OK)
catch
  getpapers(p.query, p.outdir)
results = require path.join(p.outdir, 'eupmc_results.json')
progmsg = chalk.blue("Converting paper figures to slides") +
          "\n" + chalk.yellow("[") + ":bar" + chalk.yellow("]")
progopts = {
  total: results.length,
  width: 30,
  complete: chalk.green('=')
};
ticker = new progress(progmsg, progopts);
for result in results
  ticker.tick(1)
  continue if not result
  id = getIdentifier result
  continue if id.type is 'error'
  datadir = path.join(p.outdir, id.id)
  try
    fs.accessSync(datadir, fs.F_OK)
  catch
    continue
  figdata = select_figdata datadir
  continue unless figdata.captions.length is figdata.images.length
  continue if (figdata.captions.length is 0) or (figdata.images.length is 0)
  figdata.images.forEach (figure_id, i) ->
    figure_imgs = eupmc_img_urls(id.id, figure_id)
    caption = cleanup_caption figdata.captions[i]
    frontmatter = frontmatter_from_eupmc_result(result, figure_imgs.thumb, i)
    return if not frontmatter?
    slide = slide_from_fig(caption, figure_imgs.full, frontmatter, i)
    slidefile = "#{id.id}_fig_#{i+1}.md"
    fs.writeFileSync(path.join(p.outdir, slidefile), slide)
# finally, clean up the getpapers directories
s.readdirSync(p.outdir)
  .map((f) -> path.join(p.outdir, f))
  .filter((f) -> fs.statSync(f).isDirectory())
  .forEach(removeSync)
