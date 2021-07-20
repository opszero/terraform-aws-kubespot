const core = require('@actions/core');
const github = require('@actions/github');

try {
  const githubRef = core.getInput('github-ref');
  const previewEnvName = githubRef.replace(/^refs\/heads\//, '').replace(/[^A-Za-z0-9]/g, '-')
  console.log(`Preview Env Name ${previewEnvName}!`);
  core.setOutput("preview-env-name", previewEnvName);
} catch (error) {
  core.setFailed("Failed");
}
