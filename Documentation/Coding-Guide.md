# Coding Guide

## Client Repository Structure

 - To keep all clients somewhat consistent we should keep the structure of the infrastructure repositories consistent. This will make life easier for everyone.
 - Structure:
    - infrastructure
      - terraform for terraform files
        - Ex. prod/db, prod/cluster, etc.
      - packer for packer amis
      - security/letsencrypt for LetsEncrypt

## Code

- Prefer Terraform for everything and minimize the amount of code that you have to write outside of that.
- If code is generic move it to modules or open source it.
- Preferred glue language is Python

## Git
- We use Git / Github
- Make branches and work on the branches.

```
git checkout master
git pull
git checkout -b <branch>... # Code
git add -p
git commit
git push origin <branch>
hub pull-request # Or create a Pull request on the Github repo
```

## Pull Requests

Please make pull requests even if you are not done with your work.
We want to give you feedback quickly and make sure that your code is on track.
The PullRequest should reference the Issue that is to be closed.
Say you are closing https://github.com/opszero/auditkube/issues/99
The Pull Request Message should have

  Closes #99

Docs:
https://help.github.com/articles/closing-issues-using-keywords/

## Machine Setup

 - Install VSCode
   - Install VSCode Share
 - Install EnvKey
 - Install Docker

### MacOS

```
brew install aws-sam-cli
```
