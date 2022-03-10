using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.BulkPolicing
{
    public class BulkPolicingPageObject : PageObject
    {
        public BulkPolicingPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement SearchTextField => Driver.FindElement(By.CssSelector("input[name='quickSearch']"));
        public AngularKendoGrid ResultsGrid => new AngularKendoGrid(Driver, "searchResults"); 
        public NgWebElement BulkOperationButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-list-ul"));
        public NgWebElement BulkPolicingButton => Driver.FindElement(By.CssSelector("a#bulkaction_a123_case-bulk-policing"));
        public NgWebElement BulkPolicing => Driver.FindElement(By.XPath("//span[text()='Bulk policing request']/.."));
        public NgWebElement ClearSelected => Driver.FindElement(By.XPath("//span[contains(text(),'Clear selected')]"));
        public NgWebElement BulkPolicingResultsPageTitleCount => Driver.FindElement(By.CssSelector("#caseSearchTotalRecords"));
        public NgWebElement BulkPolicingResultsPageTitle => Driver.FindElement(By.CssSelector("#quick-search-list ipx-page-title before-title span:nth-child(2)"));
        public NgWebElement SearchButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-search"));
        public NgWebElement ProceedButton => Driver.FindElement(By.CssSelector("#btnSubmit"));
        public NgWebElement TextTypeSelector => Driver.FindElement(By.CssSelector("select.ng-valid"));
        public NgWebElement DescriptionTextType => Driver.FindElement(By.XPath("//select/option[@value='7: D']"));
        public NgWebElement NewTextArea => Driver.FindElement(By.XPath("//label[text()='Notes']/following-sibling::textarea"));
        public NgWebElement RichTextArea => Driver.FindElement(By.CssSelector(".ql-editor.ql-blank"));
        public NgWebElement CaseActionInList => Driver.FindElement(By.XPath("//label[text()='Action']/following-sibling::div/following-sibling::span/span/span"));
        public NgWebElement NewActionText => Driver.FindElement(By.XPath("//td[contains(text(),'Overview')]"));
        public NgWebElement CaseLinkText => Driver.FindElement(By.XPath("//a[contains(text(), 'e2e_bu1irn')]"));
        public NgWebElement TypeText => Driver.FindElement(By.XPath("//span[text()='Description']"));
        public NgWebElement AppendedTextRow => Driver.FindElement(By.CssSelector("td>div.ng-binding.ng-scope"));
        public NgWebElement AppendedRichTextRow => Driver.FindElement(By.CssSelector("td>span.ng-binding.ng-scope"));
        public List<NgWebElement> NotificationButton => Driver.FindElements(By.CssSelector("span.notification-count")).ToList();
        public NgWebElement LatestBulkPolicingLink => Driver.FindElement(By.XPath("(//a[text()='Bulk Policing'])[1]"));
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
