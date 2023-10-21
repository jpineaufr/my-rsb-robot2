*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Desktop
Library             RPA.PDF
Library             Collections
Library             RPA.Archive
Library             OperatingSystem
Library             DateTime


*** Variables ***
${pdfs_output}              ${OUTPUT_DIR}${/}receipts
${screenshots_output}       ${OUTPUT_DIR}${/}screenshots


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    Loop the orders    ${orders}
    Create a ZIP file of receipt PDF files
    [Teardown]    End robot


*** Keywords ***
Open the robot order website
    Open Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=${True}
    RETURN    ${orders}

Loop the orders
    [Arguments]    ${orders}=${None}
    FOR    ${order}    IN    @{orders}
        Log To Console    ${order}
        Close the annoying modal
        Wait Until Keyword Succeeds
        ...    10 x
        ...    10s
        ...    Fill the form
        ...    ${order}
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order another robot
    END

Close the annoying modal
    Wait Until Element Is Visible    //div[@class="modal-dialog"]//div[@class="alert-buttons"]//button[text()="OK"]
    Click Button    //div[@class="modal-dialog"]//div[@class="alert-buttons"]//button[text()="OK"]

Fill the form
    [Arguments]    ${order}=${None}
    ${body}=    Set Variable    ${order}[Body]
    Select From List By Value    //select[@id="head"]    ${order}[Head]
    Click Element    //input[@name="body" and @value="${body}"]
    Input Text    //input[@type="number"]    ${order}[Legs]
    Input Text    //input[@id="address"]    ${order}[Address]
    Click Element    //button[@id="order"]
    Wait Until Element Is Visible    //div[@id="receipt"]

Order another robot
    Click Button    order-another

Store the receipt as a PDF file
    [Arguments]    ${orderNumber}=${None}
    ${output}=    Set Variable    ${pdfs_output}${/}${orderNumber}.pdf
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${output}
    RETURN    ${output}

Take a screenshot of the robot
    [Arguments]    ${orderNumber}=${None}
    ${output}=    Set Variable    ${screenshots_output}${/}${orderNumber}.png
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Screenshot    //div[@id="robot-preview-image"]    ${output}
    RETURN    ${output}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List
    ...    ${pdf}
    ...    ${screenshot}
    Add Files To PDF    ${files}    ${pdf}

Create a ZIP file of receipt PDF files
    ${date}=    Get Current Date
    ${timestamp}=    Convert Date    ${date}    epoch
    Archive Folder With Zip
    ...    ${pdfs_output}
    ...    ${OUTPUT_DIR}/receipts_${timestamp}.zip

End robot
    Close Browser
    Remove Directory    ${pdfs_output}    ${True}
    Remove Directory    ${screenshots_output}    ${True}
