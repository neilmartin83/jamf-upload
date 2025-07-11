# JamfMobileDeviceUploader

## Description

A processor for AutoPkg that will upload a mobile device group (smart or static) to a Jamf Cloud or on-prem server.

## Input variables

- **JSS_URL:**
  - **required:** True
  - **description:** URL to a Jamf Pro server that the API user has write access to, optionally set as a key in the com.github.autopkg preference file.
- **API_USERNAME:**
  - **required:** False
  - **description:** Username of account with appropriate access to jss, optionally set as a key in the com.github.autopkg preference file.
- **API_PASSWORD:**
  - **required:** False
  - **description:** Password of api user, optionally set as a key in the com.github.autopkg preference file.
- **CLIENT_ID:**
  - **required:** False
  - **description:** Client ID with access to access to jss, optionally set as a key in the com.github.autopkg preference file.
- **CLIENT_SECRET:**
  - **required:** False
  - **description:** Secret associated with the Client ID, optionally set as a key in the com.github.autopkg preference file.
- **mobiledevice_name**:
  - **required**: False
  - **description**: Mobile Device Group name
- **mobiledevice_template**:
  - **required**: False
  - **description**: Path to Mobile Device Group template file
- **replace_group**:
  - **required**: False
  - **description**: overwrite an existing Mobile Device Group if True.
  - **default**: False
- **sleep:**
  - **required:** False
  - **description:** Pause after running this processor for specified seconds.
  - **default:** "0"

## Output variables

- **jamfmobiledeviceuploader_summary_result:**
  - **description:** Description of interesting results.
