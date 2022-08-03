*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium  # auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Robocorp.Vault
Library    RPA.Dialogs



*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Ask assistant name
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Show Message From Local Vault
    [Teardown]    Close All Browsers

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order    headless=True

Get orders
   Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
   ${orders}=    Read table from CSV   orders.csv    header=True    delimiters=","
   RETURN    ${orders}

Close the annoying modal
    Click Button When Visible    locator=//*[@id="root"]/div/div[2]/div/div/div/div/div/button[3]

Fill the form
    [Arguments]    ${order}
    
    Select From List By Value    //*[@id="head"]    ${order}[Head]
    Click Element  //input[@type='radio' and @name='body' and @value='${order}[Body]']
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    //input[@name="address"]     ${order}[Address]

Preview the robot
    Click Button   //*[@id="preview"]

Submit the order
    Click Button   //*[@id="order"]
    ${error}=    Does Page Contain Element    //div[@class="alert alert-danger"]
    IF    ${error}
        Submit the order
    END

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}${order_number}_receipt.pdf

    RETURN    ${OUTPUT_DIR}${/}${order_number}_receipt.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    //*[@id="robot-preview-image"]    ${OUTPUT_DIR}${/}${order_number}_robot.png
    RETURN    ${OUTPUT_DIR}${/}${order_number}_robot.png
    
Embed the robot screenshot to the receipt PDF file 
    [Arguments]    ${screenshot}    ${pdf}
    ${images}=    Create List    ${screenshot}
    Add Files To Pdf    ${images}    ${pdf}    append=True
 Go to order another robot
    Click Button    //*[@id="order-another"]

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}    ${OUTPUT_DIR}${/}robot_receipts.zip    include=*.pdf  exclude=/.*

Show Message From Local Vault
    ${data}=    Get Secret    vault_data
    Log    ${data}[message]    console=True

Ask assistant name
    Add text input    name    label=Whats your name?
    ${response}=    Run dialog
    Log    ${response}[name]    console=True