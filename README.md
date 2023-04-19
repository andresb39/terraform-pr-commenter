# Terraform pull request commenter
Terraform pull requests commenter

I relied on **@robburger** repository to create this bot that comments on the Terraform PRs the changes to be applied.
[repo](https://github.com/robburger/terraform-pr-commenter)

## How to use it

### For terraoform 0.11.15
```yaml

- name: Update PR comment
  uses: andresb39/terraform-pr-commenter@tf0.11.15
 ```

### For terraoform 1.4.5
```yaml
- name: Update PR comment
  uses: andresb39/terraform-pr-commenter@tf1.4.5
 ```