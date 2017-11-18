# parastage-example

This is the example project that accommodates [my talk given at PyTexas 2017](https://docs.google.com/a/tidaltexts.com/presentation/d/12gs8zknj1r6aOQSys7y3bLVVdjw0R5JqCdQKKv-abI4/edit?usp=sharing).

This repo contains example scripts and Helm chart for deploying your own "review apps" or parallel
staging environments for each branch of your repo. The approach we use at Cratejoy follows this
workflow:
- User pushes their branch to Github
- CircleCI pushes the branch over to GitLab
- GitLab builds a new docker image for the branch + deploys the helm chart with the new image
- GitLab then reports status back to Github pull request + adds links to access the deployment

## What this repo contains

- A set of scripts (build.sh, deploy.sh, destroy.sh) that can be run by GitLab CI to build a docker
  image and deploy your Helm chart to a connected Kubernetes cluster.
- An example helm chart (charts/parastage) that what a complete config for a set of Python web apps
  with underlying data services (postgres, redis, memcache) and how they would connect.
- An example .gitlab-ci.yaml file that you could drop into your repo to orchestrate this entire
  workflow.

## Tuning Kubernetes

In my talk, I mentioned that tuning Kubernetes for this workflow is something you'll run into. There
are a few reasons you'll have to do this, not the least of which is cost.

### Just keeping things running smoothly

The nodes in your kubernetes cluster are going to be running a lot of containers and new deployments
all the time. Keeping things clean and tidy is important. Adjustments we made:
- Make sure to add extra disk space to your nodes. You're going to moving lots of images around and
  they will constantly be changing. We found that having an extra 32GB of disk went a long way, but
  you may need more or less depending on the size of your images and how many you need.
- You may need to customize the AMI you're using to launch your nodes. We found the logrotate rules
  set in the default image lead to very very large log files (syslog, daemon.log, etc) that would
  put nodes in strange states and disrupt deployments after running for a couple weeks.
- Ensure that you're using the `--purge` option when deleting the Helm releases. This will ensure
  you don't have thousands of old configs laying around, filling up your etcd cluster.

### Optimizing costs

Keep in mind that the usage pattern of your stage deployments is likely to be quite different than
that of production. Your probably going to be using these deployments really sporadically/bursty.
We found that setting really low CPU requests in the Helm chart allowed us to stuff many more
deployments on to a single node. This works fine since most deployments are not service traffic at
any given time.

If this works for you, you may find that you get more mileage out of the higher memory instance
types on your cloud provider. On AWS, the r4 class may be a better choice for this bursty type of
traffic.

# Questions?

Feel free to reach out to me on Twitter with any questions you might have:
[@joshdover](https://twitter.com/joshdover)

Looking for a new challenge? [Come work with me](https://jobs.lever.co/cratejoy) at
[Cratejoy](https://cratejoy.com)!
