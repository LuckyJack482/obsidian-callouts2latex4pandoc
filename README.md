# obsidian-callouts2latex4pandoc
Lua filters for Pandoc to generate LaTeX (thus PDF) color boxes from Obsidian style callouts (and potentially custom callouts).
The two filters are:
- [`obsidian_callouts.lua`](obsidian_callouts.lua)
- [`bang_wikilink.lua`](bang_wikilink.lua)

# Usage
Please refer to [Pandoc](https://pandoc.org/) [online manual](https://pandoc.org/MANUAL.html) ([PDF manual](https://pandoc.org/MANUAL.pdf)) to learn more about its use.
Lua filters are described in the [Lua filters page from Pandoc's website](https://pandoc.org/lua-filters.html).

The Lua filters can be used by invoking [`pandoc`](https://pandoc.org/) via command line (unix shell):
```sh
pandoc --lua-filter=obsidian_filter.lua -L=bang_wikilink.lua [...]
```
or via the [Pandoc defaults](https://pandoc.org/MANUAL.html#defaults-files) key:
```yaml
filters:
  - obsidian_callouts.lua
  - bang_wikilink.lua
```

## Example defaults file
[Pandoc defaults](https://pandoc.org/MANUAL.html#defaults-files) are a useful configuration file to invoke Pandoc
An example similiar to what I would use is [`pandoc_defaults_obsdian2latex.yaml`](pandoc_defaults_obsdian2latex.yaml). In particular:
```yaml
from: gfm+wikilinks_title_after_pipe
filters:
  - ${.}/obsidian_filter.lua
  - ${.}/bang_wikilink.lua
pdf-engine-opt: "--shell-escape"

```

# The filters
## Obsidian callouts filter
### Requirements
I personally use a GNU/Linux operating system, thus I will post only unix like commands and conventions, I am sorry for any Windows user.
#### LaTeX
By using Pandoc to generate a PDF documents, you will need a local TeX distribution such as [TeX Live](https://tug.org/texlive/).
#### Inkscape
For now, the [Lucide icons](## Icons) are SVG files, thus [Inkscape](https://inkscape.org/) is **required** in order to convert the SVG icons (the conversion is done during LaTeX compilation). Furthermore, you will need to invoke `pandoc` with the `--pdf-engine-opt="--shell-escape"` (for [TeX Live](https://tug.org/texlive/)) to allow LaTeX to do shell escaping. Please take a look at the [`svg` package](https://ctan.org/pkg/svg) [manual (page 3)](http://mirrors.ctan.org/graphics/svg/doc/svg.pdf) for more information on the shell escaping and Inkscape requirement. I am willing to remove the SVG files by statically converting them once, in order to remove all these requirements (referring to Inkscape and shell-escape option requirements).
### Icons
The icons are taken from the [Lucide](https://lucide.dev/), the default icon set used by [Obsidian](https://obsidian.md/). I downloaded the ones I need for my setup in white color (color can be customized in the web page) into the [`lucide_personal`](lucide_personal) directory, appending a `_white` suffix to each one. The downloaded icons are the one used by Obsidian plus some icons used for my custom callouts.
### Callouts
All the [default Obsidian callouts](https://help.obsidian.md/callouts#Supported%20types) are implemented. Their look is different, since they are implemented in LaTeX via the [`tcolorbox`](https://ctan.org/pkg/tcolorbox) package.

> [!NOTE]
> I am aware of the Pandoc support for [GitHub flavoured Markdown (`gfm`)](https://github.github.com/gfm/), which has its implementation of callouts (which I am using right now! ironic), called [*alerts*](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#alerts). However, these gfm alerts differ significantly from the Obsidian style callouts:
> - they **do not** support custom titles (e.g. `> [!NOTE] Note title` will not work at all, while `> [!NOTE]` will always display *Note* as the title);
> - they are not extensible (like adding custom callouts), nor editable in any form;
> - (some) colors and (some) icons of the 5 existings gfm alerts differ from the Obsidian style callouts (e.g. the `[!WARNING]` alert).
> Thus I developed this filter to enable the use of Obsidian style callouts with the power of Pandoc conversion to other formats.

> [!CAUTION]
> Title only callouts are functional but they are treated the same as callouts with content: they will generate a `tcolorbox` with empty content, leading to a white content space below the title. This can be improved by designing a better `tcolorbox` in LaTeX which does not leave an empty white space beneath the title only callout.

### Colors

| Color  | RGB             |
| ------ | --------------- |
| red    | `251, 70, 76`   |
| blue   | `2, 122, 255`   |
| cyan   | `83, 223, 221`  |
| orange | `233, 151, 110` |
| green  | `68, 207, 110`  |
| purple | `168, 130, 225` |
| gray   | `158, 157, 158` |
| yellow | `176, 187, 0`   |

All the color but for yellow are from Obsidian: the yellow color is custom since there is no yellow callout in Obsidian by default.

### My custom callouts
Based on my use of Obsidian (and consequentely [Quartz](https://github.com/jackyzha0/quartz) and [Pandoc](https://pandoc.org/)), I created few custom callouts. Particularly:
- `IMAGE`, [lucide icon `image`](https://lucide.dev/icons/image), color [blue](## Colors)
- `GRAPH`, [lucide icon `chart-line`](https://lucide.dev/icons/chart-line), color [cyan](## Colors)
- `SCHEMATIC`, [lucide icon `circuit-board`](https://lucide.dev/icons/circuit-board), color [yellow](## Colors) (I could change its name to `CIRCUIT` in the future)

## Bang wikilink filter

Another required filter was a simple filter to currectly process the Obsidian style assets (similiar to wikilinks) with a `!` in front. For instance:
```md
![[image.png]]
```
The [`bang_wikilink.lua`](bang_wikilink.lua) makes this conversion after the reading phase, so at a *abstract syntax tree* or AST level (see [Pandoc's manual](https://pandoc.org/MANUAL.html)).
This structure `[[wikilink|alternate text]]` is already currectly handled by Pandoc if the `wikilinks_title_after_pipe` extension is added to `gfm` (e.g. `pandoc --from gfm+wikilinks_title_after_pipe`), and so they do not require any custom filtering.

# Contributing
Pull requests, bug reports, and feature requests are welcome. Please feel free to contact me and contribute to this project if you want to! The code is not perfect, but hopefully clear enough.

# Attributions
The [Lucide icon set](https://github.com/lucide-icons/lucide) is licensed under the [ISC License](https://github.com/lucide-icons/lucide/blob/main/LICENSE).

Pandoc is free software, released under the [GPL](http://www.gnu.org/copyleft/gpl.html). Copyright 2006–2025 [John MacFarlane](http://johnmacfarlane.net/). 

Lua is free software distributed under the terms of the [MIT license](https://opensource.org/license/mit/).

The base of the [`obsidian_filter.lua`](obsidian_filter.lua) is [this lua script](https://github.com/iandol/dotpandoc/blob/master/filters/alerts.lua) from [iandol](https://github.com/iandol/)'s [dotfiles repository](https://github.com/iandol/dotpandoc/), licensed under the [MIT License](https://github.com/iandol/dotpandoc/blob/master/LICENSE). He was using [Typst](https://typst.app/) for his personal Lua filter, but I wanted to use LaTeX. Thanks!

Also my friends [TheICSDI](https://github.com/TheICSDI) and [mttcrn](https://github.com/mttcrn) helped me out during the writing of the scripts. Thank you!

# License
See [LICENSE](LICENSE).
