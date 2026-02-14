## Posh Wiki:


Oh My Posh is a highly customizable prompt theme engine for various shell environments, **including PowerShell, Bash, and Zsh. It allows users to configure their command prompt with various themes and segments to display information such as the current directory, git status, system load, and more.** The project is hosted on GitHub, where users can find the source code, documentation, and installation instructions. The community actively contributes to the project by reporting issues, requesting features, and submitting pull requests, I am on version 21.7.0 as of writing

**It was written by Jan De Dobbeleer and is actively developed and maintained by the community. The project is open-source and licensed under the MIT License, making it freely available for anyone to use and contribute to.** Oh My Posh is written in Go, a statically typed, compiled programming language designed for system programming. This choice of language ensures that Oh My Posh is efficient and performant across different platforms. 


## Key Features:

- ***Highly Customizable*** - Oh-My-Posh allows users to create personalized and visually appealing terminal prompts across various shell environments, including `PowerShell`, `Bash`, and `Zsh`.
- ***Segmented Themes*** - Offers a variety of themes and segments that display useful information, such as the current directory, git status, system load, and more.
- ***Cross-Platform Support*** - Compatible with multiple operating systems, making it versatile for different development environments.
- ***Ease of Use*** - Simple configuration and setup, allowing users to quickly apply and switch between different themes.  

## Best Practice:

- ***Integrate with Git*** - Make use of Oh-My-Posh’s git segment to display your current branch, status, and other git-related information for easier version control management.
- ***Optimize Performance*** - Customize your prompt to avoid displaying unnecessary information, which can slow down terminal performance.
- ***Document Your Configuration*** - Keep a backup of your configuration files to easily replicate your setup across different environments or machines.


 >Traditionally, prompt tools work with custom scripts per theme (`just like Oh My Posh 2 did`) or a lot of `CLI` configuration switches to define what it looks like. With Posh, it starts from a single configuration file that could easily be shared anywhere, removing the need to really grasp what goes on underneath.