#!/bin/bash

: <<DOC
Script to add the required credentials into your login keychain to allow repeated use.

1. Ask for the instance list, show list, ask to apply to one, multiple or all
2. Ask for the username (show any existing value of first instance in list as default)
3. Ask for the password (show the associated user if already existing)
4. Loop through each selected instance, check for an existing keychain entry, create or overwrite
5. Check the credentials are working using the API
DOC

# functions
verify_credentials() {
    local jss_url="$1"
    if [[ $verbose -gt 0 ]]; then
        echo "Verifying credentials for $jss_url"
    fi

    # check for username entry in login keychain
    # jss_api_user=$("${this_script_dir}/keychain.sh" -t internet -u -s "$jss_url")
    jss_api_user=$(/usr/bin/security find-internet-password -s "$jss_url" -g 2>/dev/null | /usr/bin/grep "acct" | /usr/bin/cut -d \" -f 4 )

    if [[ ! $jss_api_user ]]; then
        echo "No keychain entry for $jss_url found. Please run the set_credentials.sh script to add the user to your keychain"
        exit 1
    fi

    # check for password entry in login keychain
    # jss_api_password=$("${this_script_dir}/keychain.sh" -t internet -p -s "$jss_url")
    jss_api_password=$(/usr/bin/security find-internet-password -s "$jss_url" -a "$jss_api_user" -w -g 2>&1 )

    if [[ ! $jss_api_password ]]; then
        echo "No password for $jss_api_user found. Please run the set_credentials.sh script to add the password to your keychain"
        exit 1
    fi

    # echo "$jss_api_user:$jss_api_password"  # UNCOMMENT-TO-DEBUG

    # get a bearer token
    output_location="/tmp/jamf_pro_credentials_verification"
    mkdir -p "$output_location"
    output_file_token="$output_location/output_token.txt"
    output_file_record="$output_location/output_record.txt"

    http_response=$(
        curl --request POST \
        --silent \
        --user "$jss_api_user:$jss_api_password" \
        --url "$jss_url/api/v1/auth/token" \
        --write-out "%{http_code}" \
        --header 'Accept: application/json' \
        --output "$output_file_token"
    )
    echo "Token request HTTP response: $http_response"

    token=$(plutil -extract token raw "$output_file_token")

    # check Jamf Pro version
    http_response=$(
        curl --request GET \
            --silent \
            --header "authorization: Bearer $token" \
            --header 'Accept: application/json' \
            "$jss_url/api/v1/jamf-pro-version" \
            --write-out "%{http_code}" \
            --output "$output_file_record"
    )
    echo "Version request HTTP response: $http_response"
}

echo

# ------------------------------------------------------------------------------------
# 1. Ask for the instance
# ------------------------------------------------------------------------------------

echo "Enter Jamf Pro URL"
read -r -p "URL : " inputted_url
if [[ ! $inputted_url ]]; then
    echo "No username supplied"
    exit 1
fi
if [[ "$inputted_url" != "https://"* ]]; then
    inputted_url="https://$inputted_url"
fi

# ------------------------------------------------------------------------------------
# 2. Ask for the username (show any existing value of first instance in list as default)
# ------------------------------------------------------------------------------------

echo "Enter username for ${inputted_url}"
read -r -p "User : " inputted_username
if [[ ! $inputted_username ]]; then
    echo "No username supplied"
    exit 1
fi

# check for existing service entry in login keychain
instance_base="${inputted_url/*:\/\//}"
kc_check=$(security find-internet-password -s "${inputted_url}" -l "$instance_base ($inputted_username)" -a "$inputted_username" -g 2>/dev/null)

if [[ $kc_check ]]; then
    echo "Keychain entry for $inputted_username found on $instance_base"
else
    echo "Keychain entry for $inputted_username not found on $instance_base"
fi

echo
# check for existing password entry in login keychain
instance_pass=$(security find-internet-password -s "${inputted_url}" -l "$instance_base ($inputted_username)" -a "$inputted_username" -w -g 2>&1)

if [[ $instance_pass ]]; then
    echo "Password for $inputted_username found on $instance_base"
else
    echo "Password for $inputted_username not found on $instance_base"
fi

echo "Enter password for $inputted_username on $instance_base"
[[ $instance_pass ]] && echo "(or press ENTER to use existing password from keychain for $inputted_username)"
read -r -s -p "Pass : " inputted_password
if [[ "$inputted_password" ]]; then
    instance_pass="$inputted_password"
elif [[ ! $instance_pass ]]; then
    echo "No password supplied"
    exit 1
fi

# ------------------------------------------------------------------------------------
# 3. Loop through each selected instance
# ------------------------------------------------------------------------------------
echo
echo
security add-internet-password -U -s "$inputted_url" -l "$instance_base ($inputted_username)" -a "$inputted_username" -w "$instance_pass"
echo "Credentials for $instance_base (user $inputted_username) added to keychain"

# ------------------------------------------------------------------------------------
# 4. Verify the credentials
# ------------------------------------------------------------------------------------

echo
echo "Verifying credentials for $instance_base (user $inputted_username)"
verify_credentials "$inputted_url"
# print out version
version=$(plutil -extract version raw "$output_file_record")
if [[ $version ]]; then
    echo "Connection successful. Jamf Pro version: $version"
fi

echo
echo "Script complete"
echo
