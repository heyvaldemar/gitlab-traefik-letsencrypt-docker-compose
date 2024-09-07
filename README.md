# GitLab with Let's Encrypt Using Docker Compose

[![Deployment Verification](https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/actions/workflows/00-deployment-verification.yml/badge.svg)](https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/actions)

The badge displayed on my repository indicates the status of the deployment verification workflow as executed on the latest commit to the main branch.

**Passing**: This means the most recent commit has successfully passed all deployment checks, confirming that the Docker Compose setup functions correctly as designed.

📙 The complete installation guide is available on my [website](https://www.heyvaldemar.com/install-gitlab-using-docker-compose/).

❗ Change variables in the `.env` to meet your requirements.

💡 Note that the `.env` file should be in the same directory as `gitlab-traefik-letsencrypt-docker-compose.yml`.

Create networks for your services before deploying the configuration using the commands:

`docker network create traefik-network`

`docker network create gitlab-network`

Deploy GitLab using Docker Compose:

`docker compose -f gitlab-traefik-letsencrypt-docker-compose.yml -p gitlab up -d`

Visit the GitLab URL, and sign in with the username `root` and the password from the following command:

`sudo docker exec -it $(sudo docker ps -aqf "name=gitlab-gitlab-1") grep 'Password:' /etc/gitlab/initial_root_password`

Get the GitLab Runner's registration token via this link:

`https://gitlab.heyvaldemar.net/admin/runners`

Note that you need to specify the domain name of the service, previously defined in the `.env` file.

Register the GitLab Runner with an obtained token:

```
REGISTRATION_TOKEN=125DGwcgyrAsVVjUkxTL \
&& docker exec -it $(sudo docker ps -aqf "name=gitlab-runner-1") gitlab-runner register \
--non-interactive \
--url "http://gitlab/" \
--registration-token "$REGISTRATION_TOKEN" \
--executor "docker" \
--docker-image docker:stable \
--description "docker-runner-1" \
--tag-list "docker,linux" \
--run-untagged="true" \
--docker-privileged \
--output-limit "50000000" \
--access-level="not_protected" \
--docker-volumes "/var/run/docker.sock:/var/run/docker.sock"
```

# Author

I’m Vladimir Mikhalev, the [Docker Captain](https://www.docker.com/captains/vladimir-mikhalev/), but my friends can call me Valdemar.

🌐 My [website](https://www.heyvaldemar.com/) with detailed IT guides\
🎬 Follow me on [YouTube](https://www.youtube.com/channel/UCf85kQ0u1sYTTTyKVpxrlyQ?sub_confirmation=1)\
🐦 Follow me on [Twitter](https://twitter.com/heyValdemar)\
🎨 Follow me on [Instagram](https://www.instagram.com/heyvaldemar/)\
🧵 Follow me on [Threads](https://www.threads.net/@heyvaldemar)\
🐘 Follow me on [Mastodon](https://mastodon.social/@heyvaldemar)\
🧊 Follow me on [Bluesky](https://bsky.app/profile/heyvaldemar.bsky.social)\
🎸 Follow me on [Facebook](https://www.facebook.com/heyValdemarFB/)\
🎥 Follow me on [TikTok](https://www.tiktok.com/@heyvaldemar)\
💻 Follow me on [LinkedIn](https://www.linkedin.com/in/heyvaldemar/)\
🐈 Follow me on [GitHub](https://github.com/heyvaldemar)

# Communication

👾 Chat with IT pros on [Discord](https://discord.gg/AJQGCCBcqf)\
📧 Reach me at ask@sre.gg

# Give Thanks

💎 Support on [GitHub](https://github.com/sponsors/heyValdemar)\
🏆 Support on [Patreon](https://www.patreon.com/heyValdemar)\
🥤 Support on [BuyMeaCoffee](https://www.buymeacoffee.com/heyValdemar)\
🍪 Support on [Ko-fi](https://ko-fi.com/heyValdemar)\
💖 Support on [PayPal](https://www.paypal.com/paypalme/heyValdemarCOM)
