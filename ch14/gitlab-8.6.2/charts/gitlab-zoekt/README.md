# GitLab Zoekt Helm Chart

For deploying Zoekt as a code search engine to support [GitLab exact code search](https://docs.gitlab.com/ee/user/search/exact_code_search.html).

## Install the chart

```
helm install gitlab-zoekt .
```

## Enable Lefthook

```shell
lefthook install
```

## Detailed documentation

- [How to enable LoadBalancer](doc/load_balancer.md)

## Decision Making

Changes to this repository are first reviewed using the [merge request workflow](https://about.gitlab.com/handbook/engineering/development/enablement/systems/distribution/merge_requests.html) then merged by project maintainers.

### Maintainers

Project maintainers can be found on the [GitLab projects page](https://about.gitlab.com/handbook/engineering/projects/#gitlab-zoekt), or located using the [review workload dashboard](https://gitlab-org.gitlab.io/gitlab-roulette/?currentProject=gitlab-zoekt&mode=hide).

Maintainers are responsible for merging changes within their domain, and having an understanding of the whole project and how changes may impact areas outside their expertise.

Reviewers can assign to any maintainer and the maintainer will engage the appropriate domain expert if it does not fall within their own.

In order to continue to expand their expertise maintainers are empowered to merge changes outside their domain but that they are **highly confident** in unless:

- The change cannot be reverted later
- The change has an established process that needs to be followed (JiHu review, security, legal/license changes)
- The change clearly requires an architectural decision

When urgent changes are required, maintainers should have a bias-for action, and can make decisions as long as the decisions are later reversible and compliant with known project process requirements.

#### Dependency Maintainers

A dependency maintainer has the same responsibilities as a regular maintainer, but the ability to merge is tightly scoped to changes related to dependency versioning only for a specific domain. If any change aside from a dependency versioning is present in the merge request, a regular maintainer is required to perform the maintainer review.

All changes need to result in a working chart, and the impact of the change in dependency versions needs to be fully understood by the dependency maintainer. Individuals that are already chart reviewers are good candidates to become dependency maintainers.

| Username |
| -- |
| @terrichu |
| @johnmason |
