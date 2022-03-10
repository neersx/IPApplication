using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using InprotechKaizen.Model.Cases;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Interactions;
using Protractor;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.BulkUpdate
{
    public class BulkCaseNameReferenceUpdatePageObject : PageObject
    {
        public BulkCaseNameReferenceUpdatePageObject(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public NgWebElement SearchTextField => Driver.FindElement(By.CssSelector("input[name='quickSearch']"));

        public AngularKendoGrid ResultsGrid => new AngularKendoGrid(Driver, "searchResults"); 

        public NgWebElement BulkOperationButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-list-ul"));

        public NgWebElement BulkUpdateButton => Driver.FindElement(By.CssSelector("a#bulkaction_a123_case-bulk-update"));

        public NgWebElement ClearSelected => Driver.FindElement(By.XPath("//span[contains(text(),'Clear selected')]"));

        public NgWebElement ReferenceClearField => Driver.FindElement(By.XPath("(//span[text()='Remove']/..)[9]"));

        public NgWebElement SearchButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-search"));

        public NgWebElement ApplyButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-check"));

        public NgWebElement ConfirmBulkUpdate => Driver.FindElement(By.XPath("//h2[contains(text(),'Confirm Bulk Update')]"));

        public NgWebElement ProceedButton => Driver.FindElement(By.CssSelector("#btnSubmit"));

        public NgWebElement UpdateCount => Driver.FindElement(By.CssSelector(".badge"));

        public NgWebElement NameTypeSelector => Driver.FindElement(By.XPath("//label[text()='Name Type']/following-sibling::div/following-sibling::span/span/span"));

        public NgWebElement InstructorNameType => Driver.FindElement(By.XPath("//td[contains(text(),'Instructor')]"));
        public NgWebElement DebtorNameType => Driver.FindElement(By.XPath("//td[contains(text(),'Debtor')]"));
        public NgWebElement ReferenceText => Driver.FindElement(By.XPath("//label[text()='Reference']/following-sibling::input"));

        public List<NgWebElement> NotificationButton => Driver.FindElements(By.CssSelector("span.notification-count")).ToList();

        public NgWebElement LatestBulkUpdateLink => Driver.FindElement(By.XPath("(//a[text()='Bulk Update'])[1]"));

        public NgWebElement CaseLinkText => Driver.FindElement(By.XPath("//a[text()='e2e_bu1irn']"));

        public NgWebElement CaseLinkValue => Driver.FindElement(By.XPath("//a[text()='1234/G']"));

        public NgWebElement ReplaceTextInNamesGrid => Driver.FindElement(By.XPath("(//span[text()='Instructor']/../following-sibling::td)[5]/span"));

        public NgWebElement ReplaceTextForHierarchyNameTypeInNamesGrid => Driver.FindElement(By.XPath("(//span[text()='Debtor']/../following-sibling::td)[5]/span"));

    }
}
