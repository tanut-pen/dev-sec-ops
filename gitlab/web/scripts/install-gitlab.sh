#!/usr/bin/env bash

# Install and configure native GitLab CE on Ubuntu 24.04 ARM64.
# This script is deliberately idempotent: GitLab is installed only when absent,
# and reconfiguration runs only after installation or a configuration change.

set -Eeuo pipefail

readonly TIMEZONE="Asia/Bangkok"
readonly PRIVATE_IP="${1:-}"
readonly RECONFIGURE_MARKER="/etc/gitlab/.devsecops-lab-reconfigured"
readonly REPOSITORY_SETUP_URL="https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh"

log() {
  printf '[gitlab-lab] %s\n' "$*"
}

fatal() {
  printf '[gitlab-lab] ERROR: %s\n' "$*" >&2
  exit 1
}

on_error() {
  local exit_code=$?
  printf '[gitlab-lab] ERROR: provisioning failed at line %s (exit %s).\n' "${BASH_LINENO[0]}" "${exit_code}" >&2
  exit "${exit_code}"
}
trap on_error ERR

[[ ${EUID} -eq 0 ]] || fatal "Run this provisioning script as root."
[[ ${PRIVATE_IP} =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || fatal "Expected the VM private IPv4 address as argument 1."

readonly GITLAB_URL="http://${PRIVATE_IP}"

log "Verifying the guest architecture and operating system..."
[[ $(uname -m) == "aarch64" ]] || fatal "Expected uname -m to report aarch64; refusing emulation or a non-ARM guest."
[[ $(dpkg --print-architecture) == "arm64" ]] || fatal "Expected dpkg architecture arm64; refusing a non-ARM package installation."

# shellcheck disable=SC1091
source /etc/os-release
[[ ${ID:-} == "ubuntu" && ${VERSION_ID:-} == "24.04" ]] || \
  fatal "GitLab CE ARM64 provisioning is validated only for Ubuntu 24.04; detected ${PRETTY_NAME:-unknown}."

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

expand_root_filesystem() {
  local root_source volume_group physical_volume parent_disk partition_number
  local grow_output free_extents

  root_source=$(findmnt -no SOURCE /)
  if [[ ${root_source} != /dev/mapper/* ]]; then
    fatal "Expected the pinned Bento box to use LVM for its root filesystem; detected ${root_source}."
  fi

  volume_group=$(lvs --noheadings -o vg_name "${root_source}" | xargs)
  physical_volume=$(pvs --noheadings -o pv_name --select "vg_name=${volume_group}" | xargs)
  [[ ${physical_volume} == /dev/* ]] || fatal "Could not identify the physical volume for ${root_source}."

  # -d limits lsblk to the requested PV; without it, the mapped root LV is
  # included as a descendant and can add a second value to PKNAME.
  parent_disk="/dev/$(lsblk -dno PKNAME "${physical_volume}" | xargs)"
  partition_number=$(lsblk -dno PARTN "${physical_volume}" | xargs)
  [[ -b ${parent_disk} && ${partition_number} =~ ^[0-9]+$ ]] || \
    fatal "Could not identify the parent disk and partition for ${physical_volume}."

  log "Growing ${physical_volume} and ${root_source} to use the 80 GB virtual disk..."
  if ! grow_output=$(growpart "${parent_disk}" "${partition_number}" 2>&1); then
    if [[ ${grow_output} == NOCHANGE:* ]]; then
      log "The LVM partition already occupies all available virtual disk space."
    else
      fatal "growpart failed: ${grow_output}"
    fi
  fi

  pvresize "${physical_volume}"
  free_extents=$(vgs --noheadings -o vg_free_count "${volume_group}" | xargs)
  if [[ ${free_extents} =~ ^[0-9]+$ ]] && ((free_extents > 0)); then
    lvextend --extents +100%FREE --resizefs "${root_source}"
  else
    log "The root logical volume already uses all available LVM extents."
  fi

  log "Root filesystem size: $(findmnt -no SIZE /)"
}

log "Setting timezone to ${TIMEZONE}..."
if [[ $(timedatectl show --property=Timezone --value) != "${TIMEZONE}" ]]; then
  timedatectl set-timezone "${TIMEZONE}"
fi

required_packages=(curl ca-certificates openssh-server tzdata perl cloud-guest-utils lvm2)
missing_packages=()
for package in "${required_packages[@]}"; do
  if ! dpkg-query -W -f='${db:Status-Abbrev}' "${package}" 2>/dev/null | grep -q '^ii '; then
    missing_packages+=("${package}")
  fi
done

if ((${#missing_packages[@]})); then
  log "Installing required Ubuntu packages: ${missing_packages[*]}"
  apt-get update -q
  apt-get install -y --no-install-recommends "${missing_packages[@]}"
else
  log "Required Ubuntu packages are already installed."
fi

systemctl enable --now ssh.service
expand_root_filesystem

if ! grep -Rqs 'packages.gitlab.com/gitlab/gitlab-ce' \
  /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
  log "Adding the official GitLab CE package repository..."
  repository_script=$(mktemp)
  trap 'rm -f "${repository_script:-}"' EXIT
  curl --fail --silent --show-error --location \
    "${REPOSITORY_SETUP_URL}" --output "${repository_script}"
  bash "${repository_script}"
  rm -f "${repository_script}"
  trap - EXIT
else
  log "Official GitLab CE repository is already configured."
fi

log "Refreshing package metadata and verifying native Ubuntu 24.04 ARM64 availability..."
apt-get update -q
candidate=$(apt-cache policy gitlab-ce:arm64 | awk '/Candidate:/ {candidate = $2} END {print candidate}')
[[ -n ${candidate} && ${candidate} != "(none)" ]] || \
  fatal "The official repository has no GitLab CE candidate for Ubuntu 24.04 ARM64. No amd64 fallback will be used."
if ! apt-cache show gitlab-ce:arm64 2>/dev/null | grep '^Architecture: arm64$' >/dev/null; then
  fatal "The GitLab CE candidate is not a native arm64 package. No emulation will be used."
fi
log "Native GitLab CE ARM64 candidate verified: ${candidate}"

needs_reconfigure=false
if dpkg-query -W -f='${db:Status-Abbrev}' gitlab-ce 2>/dev/null | grep -q '^ii '; then
  installed_arch=$(dpkg-query -W -f='${Architecture}' gitlab-ce)
  [[ ${installed_arch} == "arm64" ]] || fatal "Installed GitLab CE architecture is ${installed_arch}, not arm64."
  log "GitLab CE is already installed; leaving the installed version unchanged."
else
  log "Installing native GitLab CE (this can take several minutes)..."
  EXTERNAL_URL="${GITLAB_URL}" apt-get install -y gitlab-ce
  needs_reconfigure=true
fi

gitlab_config=/etc/gitlab/gitlab.rb
[[ -f ${gitlab_config} ]] || fatal "GitLab configuration was not created at ${gitlab_config}."

desired_external_url="external_url '${GITLAB_URL}'"
if ! grep -Fqx "${desired_external_url}" "${gitlab_config}"; then
  log "Setting GitLab external_url to ${GITLAB_URL}..."
  if grep -Eq '^[[:space:]]*external_url[[:space:]]+' "${gitlab_config}"; then
    sed -i -E "s|^[[:space:]]*external_url[[:space:]]+.*$|${desired_external_url}|" "${gitlab_config}"
  else
    printf '\n# Managed by the Vagrant GitLab lab\n%s\n' "${desired_external_url}" >>"${gitlab_config}"
  fi
  needs_reconfigure=true
fi

if [[ ! -f ${RECONFIGURE_MARKER} ]]; then
  needs_reconfigure=true
fi

if [[ ${needs_reconfigure} == true ]]; then
  log "Running gitlab-ctl reconfigure..."
  gitlab-ctl reconfigure || fatal "gitlab-ctl reconfigure failed."
  touch "${RECONFIGURE_MARKER}"
else
  log "GitLab configuration is unchanged; reconfigure is not needed."
fi

log "Enabling GitLab services at boot..."
systemctl enable --now gitlab-runsvdir.service
gitlab-ctl start

log "Checking GitLab service status..."
gitlab-ctl status || fatal "One or more GitLab services are not running."

log "Waiting for the GitLab HTTP health endpoint..."
healthy=false
for _attempt in $(seq 1 60); do
  if curl --fail --silent --show-error --max-time 5 \
    http://127.0.0.1/-/health >/dev/null 2>&1; then
    healthy=true
    break
  fi
  sleep 5
done

if [[ ${healthy} != true ]]; then
  gitlab-ctl status >&2 || true
  fatal "GitLab did not become HTTP-ready within 5 minutes. Run: sudo gitlab-ctl tail"
fi

log "GitLab CE is healthy at ${GITLAB_URL}"
log "Architecture check: $(uname -m) (expected: aarch64)"
if [[ -f /etc/gitlab/initial_root_password ]]; then
  log "Retrieve the initial root password with: sudo cat /etc/gitlab/initial_root_password"
fi
