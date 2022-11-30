# Helium-foudnation-terraform
Helium foundation terraform for AWS infra


## On new cluster create

### Route53

First, make sure you have a route53 zone and set `zone_id`. Create a cert for that zone and put in `zone_cert`. Make sure `argo_url` matches that zone, as well as `domain_filter`

### K8s

Every shared secret in the k8s repo will need to be recreated using the new k8s.
