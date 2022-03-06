*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.Excel.Files
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Cloud.AWS
Library           RPA.FileSystem
Library           RPA.Robocorp.Vault

*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}=    ${CURDIR}${/}Temp

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${weburl}=    Get user input
    Open the robot order website    ${weburl}
    Get orders
    Fill in orders from csv data
    Create ZIP package from PDF files
    [Teardown]    Shutdown

*** Keywords ***
Get user input
    Add heading    URL for orderdata
    Add text input    url    Insert url
    ${result}=    Run dialog
    [Return]    ${result.url}

Open the robot order website
    [Arguments]    ${weburl}
    #Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Open Available Browser    ${weburl}
    Popup

Popup
    Wait Until Page Contains Element    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Click Button    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Get orders
    ${csv_url}=    Get Secret    CSV
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    Download    ${csv_url}[path]    overwrite=True

Fill in orders from csv data
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${n}    IN    @{orders}
        Work one order    ${n}
    END

Work one order
    [Arguments]    ${order}
    Input Text    address    ${order}[Address]
    Input Text    class:form-control    ${order}[Legs]
    Select From List By Value    head    ${order}[Head]
    Click Element    id-body-${order}[Body]
    Click Button    id:preview
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robot_${order}[Order number].png
    #Submit order
    Wait Until Keyword Succeeds    10x    1s    Submit order
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}receipt_${order}[Order number].pdf
    Click Button    id:order-another
    Popup
    Open Pdf    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}receipt_${order}[Order number].pdf
    ${files}=    Create List
    ...    ${OUTPUT_DIR}${/}robot_${order}[Order number].png
    Add Files To Pdf    ${files}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}receipt_${order}[Order number].pdf    True
    Close Pdf
    Remove File    ${OUTPUT_DIR}${/}receipt_${order}[Order number].pdf
    Remove File    ${OUTPUT_DIR}${/}robot_${order}[Order number].png

Submit order
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}

Shutdown
    Empty Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}
    Close Browser
