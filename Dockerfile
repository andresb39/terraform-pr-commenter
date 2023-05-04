FROM hashicorp/terraform:0.11.15

LABEL repository="https://github.com/andresb39/terraform-pr-commenter" \
    homepage="https://github.com/andresb39/terraform-pr-commenter" \
    maintainer="@andresb39" \
    com.github.actions.name="Terraform PR Commenter" \
    com.github.actions.description="Adds opinionated comments to a PR from Terraform plan" \
    com.github.actions.icon="git-pull-request" \
    com.github.actions.color="purple"

RUN apk add --no-cache -q \
    bash \
    curl \
    jq

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
