*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=False
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.Dialogs
Library             RPA.Robocloud.Secrets


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${user_input}=    Input from dialog
    Open the robot order website
    ${orders_DT}=    Get Orders    ${user_input}
    FOR    ${order}    IN    @{orders_DT}
        Remove popup
        Wait Until Keyword Succeeds    4x    1 sec    Fill the form    ${order}
        Store the receipt as a PDF file    ${order}[Order number]
        Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file
        ...    ${OUTPUT_DIR}${/}${order}[Order number].png
        ...    ${OUTPUT_DIR}${/}${order}[Order number].pdf
        Click Button    order-another
    END
    Zip receipt files
    Success dialog
    [Teardown]    CloseAllApplications


*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    URL
    Open Available Browser    ${secret}[robotorders]

Remove popup
    Click Button    OK

Get Orders
    [Arguments]    ${csv_file_path}
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True    target_file=orders.csv
    Download    ${csv_file_path}    overwrite=True    target_file=orders.csv
    ${orders_table}=    Read table from CSV    orders.csv    header=True
    RETURN    ${orders_table}

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    id-body-${row}[Body]
    Input Text    class=form-control    ${row}[Legs]
    Input Text    id=address    ${row}[Address]
    Click Button    preview
    Click Button    order
    Wait Until Element Is Visible    id=receipt    timeout=0.5

CloseAllApplications
    Close Browser

Store the receipt as a PDF file
    [Arguments]    ${file_name}
    Wait Until Element Is Visible    id=receipt
    ${receipt_html}=    Get Element Attribute    id=receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}${file_name}.pdf

Take a screenshot of the robot
    [Arguments]    ${picture_filename}
    ${screenshot}=    Screenshot    id=robot-preview-image    ${OUTPUT_DIR}${/}${picture_filename}.png
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf_file}
    Open Pdf    ${pdf_file}
    #Add Files To Pdf    ${screenshot}    target_document=${pdf_file}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf_file}
    Remove File    ${screenshot}

Zip receipt files
    Archive Folder With Zip    ${OUTPUT_DIR}    output_zipped.zip

Success dialog
    Add icon    Success
    Add heading    Your receipts are ready
    Add files    *.zip
    Run dialog    title=Success

Input from dialog
    Add heading    Where's the csv file?
    Add text input    url    label=url
    ${user_input}=    Run dialog
    RETURN    ${user_input.url}
