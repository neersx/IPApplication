using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.BulkUpdate
{
    public class BulkUpdatePageObject : PageObject
    {
        public BulkUpdatePageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement SearchTextField => Driver.FindElement(By.CssSelector("input[name='quickSearch']"));

        public AngularKendoGrid ResultsGrid => new AngularKendoGrid(Driver, "searchResults"); 

        public NgWebElement BulkOperationButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-list-ul"));

        public NgWebElement BulkUpdateButton => Driver.FindElement(By.CssSelector("a#bulkaction_a123_case-bulk-update"));

        public NgWebElement ClearSelected => Driver.FindElement(By.XPath("//span[contains(text(),'Clear selected')]"));

        public NgWebElement BulkUpdate => Driver.FindElement(By.XPath("//span[text()='Bulk update']/.."));

        public NgWebElement SelectThisPage => Driver.FindElement(By.CssSelector("a#a123_selectall"));

        public NgWebElement CaseOfficeInList => Driver.FindElement(By.CssSelector("span.cpa-icon.cpa-icon-ellipsis-h:nth-of-type(1)"));

        public NgWebElement NewOfficeText => Driver.FindElement(By.XPath("//td[contains(text(),'New Office')]"));

        public NgWebElement CaseOfficeTextField => Driver.FindElement(By.XPath("//label[text()='Case Office']/following-sibling::div/input"));

        public NgWebElement CaseOfficeClearField => Driver.FindElement(By.XPath("(//span[text()='Remove']/..)[1]"));

        public NgWebElement PurchaseOrderTextField => Driver.FindElement(By.XPath("//label[text()='Purchase Order']/following-sibling::input"));

        public NgWebElement TitleMarkTextArea => Driver.FindElement(By.XPath("//label[text()='Title/Mark']/following-sibling::textarea"));

        public NgWebElement PurchaseOrderClearField => Driver.FindElement(By.XPath("(//span[text()='Remove']/..)[4]"));

        public NgWebElement TitleMarkClearField => Driver.FindElement(By.XPath("(//span[text()='Remove']/..)[7]"));

        public NgWebElement LargeEntityInDropdown => Driver.FindElement(By.XPath("//select/option[@value='2: 2601']"));

        public NgWebElement EntitySizeClearField => Driver.FindElement(By.XPath("(//span[text()='Remove']/..)[5]"));

        public NgWebElement EntitySizeTextArea => Driver.FindElement(By.TagName("select"));

        public NgWebElement BackButton => Driver.FindElement(By.CssSelector("span.cpa-icon.cpa-icon-arrow-circle-nw"));

        public NgWebElement SearchButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-search"));

        public NgWebElement ApplyButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-check"));

        public NgWebElement ConfirmBulkUpdate => Driver.FindElement(By.XPath("//h2[contains(text(),'Confirm Bulk Update')]"));

        public NgWebElement ProceedButton => Driver.FindElement(By.CssSelector("#btnSubmit"));

        public NgWebElement SecondRecord => Driver.FindElement(By.XPath("//a[contains(text(), 'e2e_bu2irn')]"));

        public NgWebElement FirstConfirmationValue => Driver.FindElement(By.CssSelector("li:nth-of-type(1)>b"));

        public NgWebElement SecondConfirmationValue => Driver.FindElement(By.CssSelector("li:nth-of-type(2)>b"));

        public NgWebElement RemovedFieldConfirmation => Driver.FindElement(By.XPath("//div[contains(text(),'The value in the following field will be removed in the selected 2 cases')]/following-sibling::div//li"));

        public NgWebElement ReplacedFieldConfirmation => Driver.FindElement(By.XPath("//div[contains(text(),'The value in the following fields will be replaced in the selected 2 cases')]"));

        public NgWebElement ClearButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-eraser"));

        public NgWebElement BulkUpdatePageTitle => Driver.FindElement(By.CssSelector(".ipx-page-title"));

        public NgWebElement UpdateCount => Driver.FindElement(By.CssSelector(".badge"));

        public NgWebElement TextTypeSelector => Driver.FindElement(By.XPath("//label[text()='Text Type']/following-sibling::div/following-sibling::span/span/span"));

        public NgWebElement ClassSelector => Driver.FindElement(By.XPath("//label[text()='Class']/following-sibling::div/following-sibling::span/span/span"));

        public NgWebElement DescriptionTextType => Driver.FindElement(By.XPath("//td[contains(text(),'Description')]"));

        public NgWebElement GoodsAndServicesTextType => Driver.FindElement(By.XPath("//td[contains(text(),'Goods/Services')]"));

        public NgWebElement ClassTextType => Driver.FindElement(By.XPath("//td[contains(text(),'02')]"));

        public NgWebElement LanguageSelector => Driver.FindElement(By.XPath("//label[text()='Language']/following-sibling::div/following-sibling::span/span/span"));

        public NgWebElement GermanLanguage => Driver.FindElement(By.XPath("//td[contains(text(),'German')]"));

        public List<NgWebElement> NotificationButton => Driver.FindElements(By.CssSelector("span.notification-count")).ToList();

        public NgWebElement LatestBulkUpdateLink => Driver.FindElement(By.XPath("(//a[text()='Bulk Update'])[1]"));

        public NgWebElement CaseLinkText => Driver.FindElement(By.XPath("//a[contains(text(), 'e2e_bu1irn')]"));

        public NgWebElement TypeText => Driver.FindElement(By.XPath("//span[text()='Description']"));

        public NgWebElement LanguageText => Driver.FindElement(By.XPath("//span[text()='German']"));

        public NgWebElement NewTextArea => Driver.FindElement(By.XPath("//label[text()='New Text']/following-sibling::textarea"));

        public NgWebElement RichTextArea => Driver.FindElement(By.CssSelector(".ql-editor.ql-blank"));

        public NgWebElement AppendedTextRow => Driver.FindElement(By.CssSelector("td>div.ng-binding.ng-scope"));

        public NgWebElement AppendedRichTextRow => Driver.FindElement(By.CssSelector("td>span.ng-binding.ng-scope"));

        public NgWebElement ReplacedText => Driver.FindElement(By.XPath("//div[contains(text(),'Replace With This Text')]"));

        public NgWebElement FileLocationSelector => Driver.FindElement(By.XPath("//label[text()='File Location']/following-sibling::div/following-sibling::span/span/span"));

        public NgWebElement RecordsManagementFileLocation => Driver.FindElement(By.XPath("//td[contains(text(),'Records Management')]"));

        public NgWebElement MovedBySelector => Driver.FindElement(By.XPath("//label[text()='Moved By']/following-sibling::div/following-sibling::span/span/span"));

        public NgWebElement MovedByText => Driver.FindElement(By.XPath("//td[contains(text(),'Grey, George')]"));

        public AngularPicklist MovedBy => new AngularPicklist(Driver, Container).ByName("movedBy");

        public NgWebElement BayNumberInputField => Driver.FindElement(By.XPath("//label[text()='Bay Number']/following-sibling::input"));

        public NgWebElement FileLocationInCaseSearch => Driver.FindElement(By.XPath("//label[contains(text(),'File Location')]/../following-sibling::div/span"));

        public NgWebElement FileLocationUpdateRemoveButton => Driver.FindElement(By.XPath("//label[contains(text(),'File Location')]/../../../following-sibling::div//span[text()='Remove']"));

        public NgWebElement CaseStatusSelector => Driver.FindElement(By.XPath("//label[text()='Case Status']/following-sibling::div/following-sibling::span/span/span"));

        public NgWebElement CertificateReceivedStatus => Driver.FindElement(By.XPath("//td[contains(text(),'Certificate received')]"));

        public List<NgWebElement> CaseStatus => Driver.FindElements(By.XPath("//label[contains(text(),'Case Status')]/../following-sibling::div/span")).ToList();

        public NgWebElement RemoveStatusCheckbox => Driver.FindElement(By.XPath("//h1[text()='Status']/..//ipx-checkbox//span[text()='Remove']"));

        public NgWebElement ConfirmPasswordDialog => Driver.FindElement(By.CssSelector(".modal-title"));

        public NgWebElement PasswordField => Driver.FindElement(By.CssSelector("input[type=password]"));

        public NgWebElement ConfirmButton => Driver.FindElement(By.CssSelector("#btnConfirm"));

        public NgWebElement ConfirmationText => Driver.FindElement(By.XPath("//div[contains(text(), 'This status update requires a password')]"));

        public NgWebElement CancelButton => Driver.FindElement(By.CssSelector("#btnClose"));

        public NgWebElement CaseStatusValue => Driver.FindElement(By.XPath("//h1[text()='Status']/..//ipx-autocomplete"));

        public NgWebElement SanityCheckButton => Driver.FindElement(By.CssSelector("a#bulkaction_a123_sanity-check"));

        public NgWebElement LatestSanityCheckLink => Driver.FindElement(By.XPath("(//a[text()='Sanity Check'])[1]"));

        public NgWebElement StatusHeading => Driver.FindElement(By.XPath("//span[contains(text(),'Status')]"));

        public NgWebElement CaseRefHeading => Driver.FindElement(By.XPath("//span[contains(text(),'Case Ref')]"));

        public NgWebElement CaseOfficeHeading => Driver.FindElement(By.XPath("//span[contains(text(),'Case Office')]"));

        public NgWebElement CaseStaffHeading => Driver.FindElement(By.XPath("//span[contains(text(),'Staff')]"));

        public NgWebElement CaseSignatoryHeading => Driver.FindElement(By.XPath("//span[contains(text(),'Signatory')]"));

        public NgWebElement DisplayMessageHeading => Driver.FindElement(By.XPath("//span[contains(text(),'Display Message')]"));

        public NgWebElement MessageText => Driver.FindElement(By.XPath("//div[contains(text(),'Instructor is mandatory for the Case but is missing.')]"));

        public NgWebElement ExportToExcel => Driver.FindElement(By.XPath("//button[@id='exportExcel']"));

        public NgWebElement ExportToPdf => Driver.FindElement(By.XPath("//button[@id='exportPDF']"));

        public NgWebElement ExportToWord => Driver.FindElement(By.XPath("//button[@id='exportWord']"));

        public int NotificationTextCount => Convert.ToInt32(NotificationButton.First().Text);

        public void NotificationCount(int notificationCount)
        {
            var count = 0;
            while (count < 30)
            {
                Driver.WaitForAngularWithTimeout(1000);
                if (NotificationButton.Count == 1)
                {
                    if (NotificationTextCount == notificationCount + 1)
                    {
                        break;
                    }
                }

                count++;
            }
        }
    }
}