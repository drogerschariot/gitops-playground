# [Wordpress](https://opentelemetry.io/)
![opentelemetry-horizontal-color](https://github.com/drogerschariot/gitops-playground/assets/1655964/9b5ccded-e99b-420e-b77d-7aaee85f83d7)

WordPress is a widely-used content management system (CMS) that allows users to create and manage websites with ease, offering a range of customizable themes and plugins. It is known for its user-friendly interface and flexibility, catering to various website needs from blogs and business sites to e-commerce platforms.

Below will help install an instance of Wordpress with a mariadb and a public IP accessible with a self-signed certificate. 

### Wordpress Install
- `cd services/wordpress/`
- `./wordpress-up.sh`

### Otelm Demo Access
When the `wordpress-up.sh` is complete, it will output the username and password for the user, and the URL to access Wordpress. Note that since we are using a self signed certificate, you will need to accept the risk from your browser.

Example output:
```bash
-----------------
Wordpress Username: admin
Wordpress Password: AR84pnNfvS
-----------------
Wordpress is using a self signed certificate so you will need to accept the security risk.
Wordpress access http://20.241.130.143
Wordpress admin http://20.241.130.143/wp-admin
```

