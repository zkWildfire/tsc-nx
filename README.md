# tsc-nx MCVE
## Overview
This is a minimum complete verifiable example project for what seems to be a
bug in the TypeScript compiler. I originally encountered this in a project I'm
working on which uses nx to handle multiple TypeScript libraries in a monorepo.
The bug as it appears in that project is as follows:
```
Compiling TypeScript files for project "foo"...
/workspaces/foobar/foobar/node_modules/typescript/lib/typescript.js:48326
          const tsExtension = Debug.checkDefined(tryExtractTSExtension(moduleReference));
                                    ^

Error: Debug Failure.
    at resolveExternalModule (/workspaces/foobar/foobar/node_modules/typescript/lib/typescript.js:48326:37)
    at resolveExternalModuleNameWorker (/workspaces/foobar/foobar/node_modules/typescript/lib/typescript.js:48288:63)
    at resolveExternalModuleName (/workspaces/foobar/foobar/node_modules/typescript/lib/typescript.js:48285:14)
    at checkImportDeclaration (/workspaces/foobar/foobar/node_modules/typescript/lib/typescript.js:81697:37)
    at checkSourceElementWorker (/workspaces/foobar/foobar/node_modules/typescript/lib/typescript.js:82181:18)
    at checkSourceElement (/workspaces/foobar/foobar/node_modules/typescript/lib/typescript.js:81998:9)
    at forEach (/workspaces/foobar/foobar/node_modules/typescript/lib/typescript.js:55:24)
    at checkSourceFileWorker (/workspaces/foobar/foobar/node_modules/typescript/lib/typescript.js:82371:9)
    at checkSourceFile (/workspaces/foobar/foobar/node_modules/typescript/lib/typescript.js:82338:7)
    at checkSourceFileWithEagerDiagnostics (/workspaces/foobar/foobar/node_modules/typescript/lib/typescript.js:82432:7)
```
> The project I'm working on is not currently open source, so references to the
> project have been replaced with "foobar" and "foo" in the above message.

## Reproducing the bug
I was able to reproduce this bug and isolate it to only occurring when loading
a type from an `index.ts` file in a subdirectory of a library. It should be
possible for anyone to repro this bug by loading up this repository in VSCode
and using VSCode's devcontainers support to load the project in a container.
This will set up dependencies like npm and of course, tsc.

I've added two nx workspaces to this project, `working` and `buggy`. Both
workspaces contain two TypeScript libraries, `foo` and `bar`. `bar` defines a
single type that is exported. `foo` contains a single source file that imports
the type from `bar`. The only difference between the two workspaces is that
the type is exported from `@working/bar` via the `bar/src/index.ts` file, and
`buggy` exports the type from `@buggy/bar/baz` via `bar/src/baz/index.ts`.

To reproduce this bug, `cd` into `buggy` and run `nx build foo`. This should
result in an error message like the one provided above. You can also verify
that the issue does not arise in the `working` workspace by running the same
command in that workspace.

I'm not quite clear on whether this issue is related to how nx sets up imports
between libraries as I'm relatively new to both nx and TypeScript. However,
seeing as the error is coming from TypeScript's code, I don't think this is
something that should be happening regardless of how nx configures TypeScript.

## Setup
Below is a list of all commands I ran to set up this project, along with any
relevant information:
```sh
# Create the two workspaces as mostly empty nx workspaces
# cwd: <repo_root>
npx create-nx-workspace@latest --name working --preset ts --workspaceType integrated --nxCloud false
npx create-nx-workspace@latest --name buggy --preset ts --workspaceType integrated --nxCloud false

# Create the two libraries in each workspace
# These commands were run twice, once in `<repo_root>/working` and again in
#   `<repo_root>/buggy`.
nx g @nx/js:lib --name foo --bundler tsc --unitTestRunner jest
nx g @nx/js:lib --name bar --bundler tsc --unitTestRunner jest
```