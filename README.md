<a name="readme-top"></a>

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

<br />
<div align="center">
  <a href="https://github.com/Cassin01/wf.nvim">
    <img src=".github/images/logo.png" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">wf.nvim</h3>

  <p align="center">
    A which-key with a fuzzy-find.
    <br />
    <a href="https://github.com/Cassin01/wf.nvim"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/Cassin01/wf.nvim">View Demo</a>
    ·
    <a href="https://github.com/Cassin01/wf.nvim/issues">Report Bug</a>
    ·
    <a href="https://github.com/Cassin01/wf.nvim/issues">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->
## About The Project

<div align="center">
    <!-- > Drag your video (<10MB) here to host it for free on GitHub. -->

[![Product Name Screen Shot][product-screenshot]](https://github.com/Cassin01/wf.nvim)

</div>

<div align="center">

<!-- > Videos don't work on GitHub mobile, so a GIF alternative can help users. -->

_[GIF version of the showcase video for mobile users](SHOWCASE_GIF_LINK)_

</div>

This plugin is yet another `vim.ui.select` alternative. This plugin also provides `which-key`, `marker`, `bookmark`, `buffer` pikers.

Here's why:
* You can use fuzzy find when searching docs.
* Neovim's "docs" feature.
* You can skip duplicate characters.

Have a ball!

<p align="right">(<a href="#readme-top">back to top</a>)</p>



## ⚡️ Features

> Write short sentences describing your plugin features

- FEATURE 1
- FEATURE ..
- FEATURE N

## 📋 Installation

<div align="center">
<table>
<thead>
<tr>
<th>Package manager</th>
<th>Snippet</th>
</tr>
</thead>
<tbody>
<tr>
<td>

[wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim)

</td>
<td>

```lua
-- stable version
use {"wf", tag = "*" }
-- dev version
use {"wf"}
```

</td>
</tr>
<tr>
<td>

[junegunn/vim-plug](https://github.com/junegunn/vim-plug)

</td>
<td>

```lua
-- stable version
Plug "wf", { "tag": "*" }
-- dev version
Plug "wf"
```

</td>
</tr>
<tr>
<td>

[folke/lazy.nvim](https://github.com/folke/lazy.nvim)

</td>
<td>

```lua
-- stable version
require("lazy").setup({{"wf", version = "*"}})
-- dev version
require("lazy").setup({"wf"})
```

</td>
</tr>
</tbody>
</table>
</div>

## ☄ Getting started

> Describe how to use the plugin the simplest way

## ⚙ Configuration

> The configuration list sometimes become cumbersome, making it folded by default reduce the noise of the README file.

<details>
<summary>Click to unfold the full list of options with their default values</summary>

> **Note**: The options are also available in Neovim by calling `:h wf.options`

```lua
require("wf").setup({
    -- you can copy the full list from lua/wf/config.lua
})
```

</details>

## 🧰 Commands

|   Command   |         Description        |
|-------------|----------------------------|
|  `:Toggle`  |     Enables the plugin.    |

## ⌨ Contributing

PRs and issues are always welcome. Make sure to provide as much context as possible when opening one.

## 🗞 Wiki

You can find guides and showcase of the plugin on [the Wiki](https://github.com/cassin/wf.nvim/wiki)

## 🎭 Motivations

> If alternatives of your plugin exist, you can provide some pros/cons of using yours over the others.


<!-- MARKDOWN LNIKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/Cassin01/wf.nvim.svg?style=for-the-badge
[contributors-url]: https://github.com/Cassin01/wf.nvim/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/Cassin01/wf.nvim.svg?style=for-the-badge
[forks-url]: https://github.com/Cassin01/wf.nvim/network/members
[stars-shield]: https://img.shields.io/github/stars/Cassin01/wf.nvim.svg?style=for-the-badge
[stars-url]: https://github.com/Cassin01/wf.nvim/stargazers
[issues-shield]: https://img.shields.io/github/issues/Cassin01/wf.nvim.svg?style=for-the-badge
[issues-url]: https://github.com/Cassin01/wf.nvim/issues
[license-shield]: https://img.shields.io/github/license/Cassin01/wf.nvim.svg?style=for-the-badge
[license-url]: https://github.com/Cassin01/wf.nvim/blob/main/LICENSE.txt
[product-screenshot]: https://user-images.githubusercontent.com/42632201/213849418-3cddb8bb-7323-4af7-b201-1ce2de07d3b9.png
