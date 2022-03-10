using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Interactions;
using System.Linq;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.BulkPolicing
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "14.0")]
    public class BulkPolicing : IntegrationTest
    {
        [TearDown]
        public void CleanupModifiedData()
        {
            DbSetup.Do(x =>
            {
                var shouldEnableRichTextFormatting = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.EnableRichTextFormatting);
                shouldEnableRichTextFormatting.BooleanValue = false;
                x.DbContext.SaveChanges();
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void BulkPolicingGetsDisabledOnSelectingClear(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkPolicingPageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys(Keys.Enter).Build().Perform();
            page.ResultsGrid.SelectRow(0);
            page.BulkOperationButton.Click();
            driver.WaitForAngular();
            Assert.AreNotEqual("disabled", page.BulkPolicing.GetAttribute("class"));

            page.ClearSelected.Click();
            driver.WaitForAngular();
            Assert.AreEqual("disabled", page.BulkPolicing.GetAttribute("class"));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void BulkPolicingPageSaveFunctionality(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var ct = x.DbContext.Set<Country>().FirstOrDefault(_ => _.Id == "AU");
                var pt = x.DbContext.Set<PropertyType>().FirstOrDefault(_ => _.Code == "T");
                new CaseBuilder(x.DbContext).Create("e2e_bu1", true, null, ct, pt);
                new CaseBuilder(x.DbContext).Create("e2e_bu2");
                x.DbContext.SaveChanges();
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkPolicingPageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys("e2e_bu").Build().Perform();
            driver.WaitForAngular();
            page.SearchButton.Click();
            page.ResultsGrid.SelectRow(0);
            page.ResultsGrid.SelectRow(1);
            page.BulkOperationButton.Click();
            page.BulkPolicingButton.Click();

            Assert.IsNotNull(page.ProceedButton.GetAttribute("disabled"));
            page.CaseActionInList.Click();
            page.NewActionText.Click();
            Assert.IsNull(page.ProceedButton.GetAttribute("disabled"));

            page.TextTypeSelector.Click();
            page.DescriptionTextType.Click();
            page.NewTextArea.SendKeys("APPEND TO Description");

            var notificationCount = page.NotificationButton.Count == 0 ? 0 : page.NotificationTextCount;
            page.ProceedButton.Click();

            page.NotificationCount(notificationCount);
            page.NotificationButton.First().Click();
            page.LatestBulkPolicingLink.Click();
            driver.WaitForAngular();
            Assert.AreEqual("2", page.BulkPolicingResultsPageTitleCount.Text.Trim());
            Assert.AreEqual("Bulk Policing Results", page.BulkPolicingResultsPageTitle.Text.Trim());

            page.CaseLinkText.Click();
            Assert.IsTrue(page.TypeText.Displayed);
            StringAssert.Contains("APPEND TO Description", page.AppendedTextRow.Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void BulkPolicingPageIsEditableWhenEnableRichTextFormatting(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var shouldEnableRichTextFormatting = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.EnableRichTextFormatting);
                shouldEnableRichTextFormatting.BooleanValue = true;
                var ct = x.DbContext.Set<Country>().FirstOrDefault(_ => _.Id == "AU");
                var pt = x.DbContext.Set<PropertyType>().FirstOrDefault(_ => _.Code == "T");
                new CaseBuilder(x.DbContext).Create("e2e_bu1", true, null, ct, pt);
                x.DbContext.SaveChanges();
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkPolicingPageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys("e2e_bu1").Build().Perform();
            driver.WaitForAngular();
            page.SearchButton.Click();
            page.ResultsGrid.SelectRow(0);
            page.BulkOperationButton.Click();
            page.BulkPolicingButton.Click();

            page.CaseActionInList.Click();
            page.NewActionText.Click();
            page.TextTypeSelector.Click();
            page.DescriptionTextType.Click();
            Assert.AreEqual("Please enter text here", page.RichTextArea.GetAttribute("data-placeholder"));
            driver.WaitForAngularWithTimeout(2000);
            driver.ExecuteScript("document.querySelectorAll('.ql-editor')[0].textContent='APPEND TO Description'");
            var notificationCount = page.NotificationButton.Count == 0 ? 0 : page.NotificationTextCount;
            page.ProceedButton.Click();

            page.NotificationCount(notificationCount);
            page.NotificationButton.First().Click();
            page.LatestBulkPolicingLink.Click();
            driver.WaitForAngular();

            page.CaseLinkText.Click();
            Assert.IsTrue(page.TypeText.Displayed);
            StringAssert.Contains("APPEND TO Description", page.AppendedRichTextRow.Text);
        }
    }
}
