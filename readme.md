# Chocolatey Azure DevOps Tasks

This extension brings support for [Chocolatey](https://chocolatey.org/) to Azure DevOps.

## Table of Contents

1. [What is Chocolatey?](#what-is-chocolatey)
1. [Tasks](#tasks)
1. [Resources](#resources)
1. [Thanks](#thanks)
1. [Contributing](#contributing)
1. [Releases](#releases)

## What is Chocolatey?

Chocolatey is a Package Manager for Windows, which allows the automation of all your software needs.

For more information about [Chocolatey](https://chocolatey.org/), please see the Chocolatey Website or the Chocolatey [source code repository](https://github.com/chocolatey/choco).


## Tasks

This extension contains only a single Task, which is capable of executing the following Chocolatey Commands:

**NOTE:** This Azure DevOps Task assumes that Chocolatey is already installed on the Build Agent that is running the build.  If Chocolatey is not located on the Build Agent, an error will be thrown, and the task will fail.

* apikey
* config
* custom
* feature
* install
* pack
* push
* source
* upgrade

## Resources

Short YouTube videos of each of the releases of this extension can be found in this [playlist](https://www.youtube.com/playlist?list=PL84yg23i9GBhGahFf5-41vOJhn3D-6EUU).

## Thanks

The Chocolatey Azure DevOps Extension is modelled on the NuGet Extension, and many of the ideas in terms of how it functions, is based on how it works.

## Contributing

If you would like to see any other tasks or features added for this Azure DevOps Extension, feel free to raise an [issue](https://github.com/gep13/chocolatey-azuredevops/issues), and if possible, a follow up pull request.

You can also join in the Gitter Chat [![Join the chat at https://gitter.im/gep13/chocolatey-azuredevops](https://badges.gitter.im/gep13/chocolatey-azuredevops.svg)](https://gitter.im/gep13/chocolatey-azuredevops?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

## Releases

To find out what was released in each version of this extension, check out the [releases](https://github.com/gep13/chocolatey-azuredevops/releases) page.
