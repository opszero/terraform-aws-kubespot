const core = require('@actions/core');
const github = require('@actions/github');

try {
  const githubRef = core.getInput('github-ref').replace(/^refs\/heads\//, '');
  const previewEnvName = githubRef.replace(/[^A-Za-z0-9]/g, '-')
  console.log(`Preview Env Name ${previewEnvName}!`);

  const isPreview = !!githubRef.match(/^(bug|epic|feature_deploy)/)
  console.log(`Is Preview: ${isPreview}!`);

  core.setOutput("preview-env-name", previewEnvName);
  core.setOutput("is-preview", isPreview);
} catch (error) {
  core.setFailed("Failed");
}
