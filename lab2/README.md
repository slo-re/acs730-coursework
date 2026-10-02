# Lab 2: EC2 Web Application with systemd

## Deployment
I worked from my Week 1 workstation and deployed to a separate Amazon Linux 2023 t3.micro instance using my custom SSH key. I performed the deployment as acs730admin.

The deploy script installs Python with dnf, creates acs730web if it does not exist, and writes the webpage into /opt/acs730-web with the correct ownership. It then installs the systemd unit, reloads systemd, enables the service, and restarts it. I checked the website from the workstation and confirmed that it returned automatically after reboot.

## Security
SSH is restricted to the workstation's public IP using /32 because only that machine needs administrative access. HTTP is open to 0.0.0.0/0 so visitors can access the website.

The application runs as acs730web, a service account with no login shell or sudo access. CAP_NET_BIND_SERVICE allows it to use port 80 without running as root. I added an explicit passwordless sudo rule for acs730admin because wheel membership alone did not pass the sudo check on this instance.

## Start and enable
systemctl start runs a service now, while systemctl enable configures it to start automatically at boot.
## Experiments

### 1. Start without enable
Prediction: I predict that disabling the service will leave the website running until the server is rebooted. When rebooted, I think the website will be unavailable because the service is no longer configured to start automatically.

Observation: The service stayed active after I disabled it. After reboot, it was inactive and disabled, and the website could not be reached. This showed that running now and starting automatically at boot are separate settings. I restored the service with `systemctl enable --now`.

### 5. Break the idempotency
Prediction: Without the check for an existing service user, both test runs will fail at `useradd` because `acs730web` already exists. The script will stop there because of `set -e`.

Observation: Both runs failed at `useradd` because `acs730web` already existed, returning exit code 9. `set -e` stopped the script before the remaining deployment steps. Checking whether the user already exists allows the deployment script to run again safely.
