<#

.SYNOPSIS
List Contacts on a Zoom account.

.DESCRIPTION
List Contacts on a Zoom account. The Zoom API works similarly to browsing contacts on Zoom's website.
Because of this, API calls require a page number (default is 1) and page size (default is 30). 

.PARAMETER PageSize
The number of records returned within a single API call. Default value is 30. Maximum value is 300.

.PARAMETER PageNumber
The current page number of returned records. Default value is 1.

.PARAMETER FullApiResponse
The switch FullApiResponse will return the default Zoom API response.

.PARAMETER AllPages
Returns all pages. The default API response returns the first page of contacts. This loops through each page
and puts them together then returns all of the results.

.PARAMETER ApiKey
The Api Key.

.PARAMETER ApiSecret
The Api Secret.

.LINK
https://marketplace.zoom.us/docs/api-reference/zoom-api/contacts/contacts

.EXAMPLE
Return the first page of active contacts.
Get-ZoomContacts

.EXAMPLE
Return contacts emails.
(Get-ZoomContacts -PageSize 300 -pagenumber 3).Email

.EXAMPLE
Return all contacts.
Get-ZoomContacts -AllPages
#>

function Get-ZoomContacts {
    [CmdletBinding()]
    param (
        [Parameter(
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = 'Default'
        )]
        [Parameter(
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = 'All'
        )]
        [Parameter(
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = 'FullApiResponse'
        )]
        [ValidateRange(1, 300)]
        [Alias('page_size')]
        [int]$PageSize = 30,

        # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
        [Alias('next_page_token')]
        [string]$NextPageToken,

        [Parameter(
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = 'Default'
        )]
        [Parameter(
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = 'All'
        )]
        [Parameter(
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = 'FullApiResponse'
        )]
        [Alias('page_number')]
        [int]$PageNumber = 1,

        [Parameter(
            ParameterSetName = 'FullApiResponse', 
            Mandatory = $True
        )]
        [switch]$FullApiResponse,

        [Parameter(
            ParameterSetName = 'All', 
            Mandatory = $True
        )]
        [switch]$AllPages,

        [ValidateNotNullOrEmpty()]
        [string]$ApiKey,

        [ValidateNotNullOrEmpty()]
        [string]$ApiSecret
    )

    begin {
        #Generate Header with JWT (JSON Web Token) using the Api key/secret
        $Headers = New-ZoomHeaders -ApiKey $ApiKey -ApiSecret $ApiSecret
    }

    process {
        $Request = [System.UriBuilder]'https://api.zoom.us/v2/contacts/'
        $query = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        $query.Add('page_size', $PageSize)
#        $query.Add('page_number', $PageNumber)

        $Request.Query = $query.ToString()
        $response = Invoke-ZoomRestMethod -Uri $request.Uri -Headers ([ref]$Headers) -Method GET -ApiKey $ApiKey -ApiSecret $ApiSecret

        if ($FullApiResponse) {
            Write-Output $response
        } elseif ($AllPages) {
            $allcontacts = @()

            do {
                $result = Get-ZoomContacts -PageNumber $pageCount -PageSize 300 -FullApiResponse

                if ($result.Contacts) {
                    Write-Verbose "Adding contacts from page $pageCount"
                    $allcontacts += (Get-ZoomContacts -PageNumber $pageCount -PageSize 300 -FullApiResponse).Contacts
                }

                if ($result.next_page_token) {
                    $query.Add('next_page_token', $result.next_page_token)
                }
            } while ($result.next_page_token)

            Write-Output $allcontacts
        } else {
            Write-Output $response.contacts
        }
    }
}
