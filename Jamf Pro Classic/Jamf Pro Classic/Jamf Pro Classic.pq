// This file contains your Data Connector logic
section #"Jamf Pro Classic";

//[DataSource.Kind = "Jamf Pro Classic", Publish = "Jamf Pro Classic.Publish"]
//shared #"Jamf Pro Classic.Feed" = Value.ReplaceType(JamfURL, type function (url as Uri.Type) as any);

[DataSource.Kind = "Jamf Pro Classic", Publish = "Jamf Pro Classic.Publish"]
shared #"Jamf Pro Classic.Contents" = Value.ReplaceType(JamfURL, JamfPrompt);

ValidateUrlScheme = (url as text) as text => if (Uri.Parts(url)[Scheme] <> "https") then error "Url scheme must be HTTPS" else url;

JamfPrompt = type function (
    baseurl as (type text meta [
        Documentation.FieldCaption = "Jamf Pro URL",
        Documentation.FieldDescription = "Enter your Jamf Pro URL.",
        Documentation.SampleValues = {"https://jamf.jamfcloud.com", "https://jamf.jamf.local"}
    ]),
    optional port as (type text meta [
        Documentation.FieldCaption = "Jamf URL Port",
        Documentation.FieldDescription = "Enter your Jamf Pro port connection if different from 443.",
        Documentation.SampleValues = {"8443"}
    ]))
    as table meta [
        Documentation.Name = "Jamf Pro Classic API Connection",
        Documentation.LongDescription = "Gather data from your Jamf instance using the classic API connection."
    ];
JamfURL = (baseurl as text, optional port as text) =>
    let
        port443 = baseurl,
        portOther = Text.Combine({baseurl, port}, ":"),
        jamfURL = if (port <> null) then portOther else port443,
        jamfTable = jamfURL
    in
        jamfURL;

// Source URLs
JSSResource = (url as text, relativepath as text) =>
    let
        source = Web.Contents(url & "/JSSResource", [
            Headers = [
                #"Accept" = "application/xml"
            ],
            RelativePath = relativepath
        ])
    in
        source;
GetJSSResource = (id as number, url as text, path as text) =>
    let
        source = JSSResource(url,path & Number.ToText(id)),
        result = Xml.Tables(source)
        
    in
        result;
GetJssResourceWithSuffix = (id as number, baseurl as text,path as text, suffix as text) as any =>
    let
        response = JSSResource(baseurl,path & Number.ToText(id) & suffix),
        result = Xml.Tables(response)
        
    in
        result;
// Data Source Kind description
#"Jamf Pro Classic" = [
    Authentication = [
        UsernamePassword = [
            UsernameLabel = "Enter your Jamf Pro username.",
            PasswordLabel = "Enter your Jamf Pro password."
        ]
    ],
    Label = "Jamf Pro Classic API Connection"
];
// Data Source UI publishing description
#"Jamf Pro Classic.Publish" = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = "Jamf Pro Classic.Icons",
    SourceTypeImage = "Jamf Pro Classic.Icons"
];
#"Jamf Pro Classic.Icons" = [
    Icon16 = { Extension.Contents("JamfProClassic16.png"), Extension.Contents("JamfProClassic20.png"), Extension.Contents("JamfProClassic24.png"), Extension.Contents("JamfProClassic32.png") },
    Icon32 = { Extension.Contents("JamfProClassic32.png"), Extension.Contents("JamfProClassic40.png"), Extension.Contents("JamfProClassic48.png"), Extension.Contents("JamfProClassic64.png") }
];
// Navigation Table
Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;