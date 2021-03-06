#!/usr/bin/env bash

if [ "$#" -lt 2 ]; then
  echo -e "\033[1mPrepares the vendor directory (or restore it from cache) for a specific PHP and Codeception version combination.\033[0m"
  echo ""
  echo -e "\033[32mUsage:\033[0m"
  echo "  vendor_prepare.sh <php_version> <codeception_version> [<composer_version>] [<cache_directory>:/tmp]"
  echo ""
  echo -e "\033[32mExamples:\033[0m"
  echo ""
  echo "  Prepare the vendor directory for PHP 5.6, Codeception ^3.0,Composer v1 and cache to /tmp"
  echo -e "  \033[36mvendor_prepare.sh 5.6 3.0 1\033[0m"
  echo "  Prepare the vendor directory for PHP 7.1, Codeception ^4.0,Composer v2 and cache to /tmp"
  echo -e "  \033[36mvendor_prepare.sh 7.1 4.0 2\033[0m"
  echo ""
  echo "  Prepare the vendor directory for PHP 7.3 and Codeception ^2.5, Composer v2 and cache to /private/temp"
  echo -e "  \033[36mvendor_prepare.sh 7.3 2.5 2 /private/temp\033[0m"
  exit 0
fi

test "${OSTYPE}" == "linux-gnu" && export FIXUID=1 || export FIXUID=0
php_version="$1"
codeception_version="$2"
# Default the Composer version to 2 if not specified.
composer_version="${3:-2}"
cache_dir="${4:-/tmp}"
project="$(basename "${PWD}")"
cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -f .ready ]; then
  echo -e "\033[32m.ready file found in working directory ($(<"${PWD}"/.ready))\033[0m"
  ready=$(<"${PWD}/.ready")
else
  ready=0
fi

if [ ${ready} != 0 ] && [ ${ready} != "${php_version}.cc.${codeception_version}.composer.${composer_version}" ] && [ -d "${PWD}/vendor" ]; then
  vendor_cache="${cache_dir}/vendor-${project}-${ready}"

  test -d "${vendor_cache}" && rm -rf "${vendor_cache}"

  mv "${PWD}"/vendor "${vendor_cache}" || \
    (echo -e "\033[91mCould not move vendor directory to ${vendor_cache}\033[0m"; exit 1)

  mv "${PWD}"/composer.json "${vendor_cache}/composer.json" || \
    (echo -e "\033[91mCould not move composer.json to ${vendor_cache}/composer.json\033[0m"; exit 1)

  mv "${PWD}"/composer.lock "${vendor_cache}/composer.lock" || \
    (echo -e "\033[91mCould not move composer.lock to ${vendor_cache}/composer.lock\033[0m"; exit 1)

  rm -f "${PWD}"/composer.lock

  echo -e "\033[32mVendor directory cached to ${vendor_cache}\033[0m"
fi

if [ ! -f "${PWD}/.ready" ] || [ ! -d "${PWD}/vendor" ]; then
  current_vendor_cache="${cache_dir}/vendor-${project}-${php_version}.cc.${codeception_version}"

  if [ -d "${current_vendor_cache}" ]; then
    if mv "${current_vendor_cache}/composer.json" "${PWD}"/composer.json; then
        echo -e "\033[32mcomposer.json restored from cache\033[0m"
    else
      echo -e "\033[91mCould not restore composer.json from cache\033[0m"
    fi

    if mv "${current_vendor_cache}/composer.lock" "${PWD}"/composer.lock; then
        echo -e "\033[32mcomposer.lock restored from cache\033[0m"
    else
      echo -e "\033[91mCould not restore composer.lock from cache\033[0m"
    fi

    if mv "${current_vendor_cache}" "${PWD}"/vendor; then
        echo -e "\033[32mVendor directory restored from cache\033[0m"
    else
      echo -e "\033[91mCould not restore vendor directory from cache\033[0m"
    fi
  else
    echo -e "\033[91mVendor directory cache not found, updating.\033[0m"
    git checkout "${PWD}/composer.json"
    test -f "${cwd}/required-packages-${codeception_version}" \
      && { \
        echo "Reading packages from file ${cwd}/required-packages-${codeception_version}"; \
        required_packages="$(<"${cwd}/required-packages-${codeception_version}")"; \
        } \
      || { \
        echo "File ${cwd}/required-packages-${codeception_version} not found, requiring codeception/codeception:^${codeception_version}"; \
        required_packages="codeception/codeception:^${codeception_version}"; \
        }

    if [ "${FIXUID}" == 1 ]; then
      docker run --rm \
        --user "$(id -u):$(id -g)" \
        -e FIXUID=1 \
        -v "${HOME}/.composer/auth.json:/composer/auth.json" \
        -v "${PWD}:/project" \
        -t \
        lucatume/composer:php"${php_version}-composer-v${composer_version}" require $required_packages
    else
      docker run --rm \
        -e FIXUID=0 \
        -v "${HOME}/.composer/auth.json:/composer/auth.json" \
        -v "${PWD}:/project" \
        -t \
        lucatume/composer:php"${php_version}-composer-v${composer_version}" require $required_packages
    fi

    echo -e "\033[32mVendor directory ready for PHP ${php_version} and Codeception ${codeception_version}.\033[0m"
  fi
fi

test -d "${PWD}/vendor" || { echo "${PWD}/vendor directory not found."; exit 1; }

echo "${php_version}.cc.${codeception_version}.composer.${composer_version}" > "${PWD}/.ready"

echo -e "\033[32mDone.\033[0m"
