using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using NUnit.Framework;
using OpenQA.Selenium.Interactions;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.BulkUpdate
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class BulkCaseNameReferenceUpdate : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void BulkUpdateOfCaseNameReferenceUpdate(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var ct = x.DbContext.Set<Country>().FirstOrDefault(_ => _.Id == "AU");
                var pt = x.DbContext.Set<PropertyType>().FirstOrDefault(_ => _.Code == "T");
                var @case = new CaseBuilder(x.DbContext).Create("e2e_bu1", true, null, ct, pt);
                var nameType = x.DbContext.Set<NameType>().FirstOrDefault();
                var name = x.DbContext.Set<Name>().FirstOrDefault();
                var caseName = new CaseName(@case, nameType, name,0 ) {Reference = "TESTING"};
                x.DbContext.Set<CaseName>().Add(@caseName);
                x.DbContext.SaveChanges();

            });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkCaseNameReferenceUpdatePageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys("e2e_bu1").Build().Perform();
            driver.WaitForAngular();
            page.SearchButton.Click();
            page.ResultsGrid.SelectRow(0);
            page.BulkOperationButton.Click();
            page.BulkUpdateButton.Click();
            page.NameTypeSelector.Click();
            page.InstructorNameType.Click();
            page.ReferenceText.SendKeys("Testing Reference");
            var notificationCount = 0;
            notificationCount = page.NotificationButton.Count==0 ? 0 : Convert.ToInt32(page.NotificationButton.First().Text);
            page.ApplyButton.Click();
            Assert.IsTrue(page.ConfirmBulkUpdate.Displayed);
            page.ProceedButton.Click();
            var count = 0;
            while (count < 30)
            {
                
                driver.WaitForAngularWithTimeout(1000);
                if (page.NotificationButton.Count == 1)
                {
                    var updatedNotificationCount = Convert.ToInt32(page.NotificationButton.First().Text);
                    if (updatedNotificationCount == notificationCount + 1)
                        break;
                }

                count++;
            }
            page.NotificationButton.First().Click();
            page.LatestBulkUpdateLink.Click();
            page.CaseLinkText.Click();
            StringAssert.DoesNotContain("TESTING",page.ReplaceTextInNamesGrid.Text);
            StringAssert.Contains("Testing Reference",page.ReplaceTextInNamesGrid.Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void BulkUpdateOfCaseNameReferenceDelete(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var ct = x.DbContext.Set<Country>().FirstOrDefault(_ => _.Id == "AU");
                var pt = x.DbContext.Set<PropertyType>().FirstOrDefault(_ => _.Code == "T");
                var @case = new CaseBuilder(x.DbContext).Create("e2e_bu1", true, null, ct, pt);
                var nameType = x.DbContext.Set<NameType>().FirstOrDefault();
                var name = x.DbContext.Set<Name>().FirstOrDefault();
                var caseName = new CaseName(@case, nameType, name,0 ) {Reference = "TESTING"};
                x.DbContext.Set<CaseName>().Add(@caseName);
                x.DbContext.SaveChanges();

            });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkCaseNameReferenceUpdatePageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys("e2e_bu1").Build().Perform();
            driver.WaitForAngular();
            page.SearchButton.Click();
            page.ResultsGrid.SelectRow(0);
            page.BulkOperationButton.Click();
            page.BulkUpdateButton.Click();
            page.NameTypeSelector.Click();
            page.InstructorNameType.Click();
            page.ReferenceClearField.Click();
            var notificationCount = 0;
            notificationCount = page.NotificationButton.Count==0 ? 0 : Convert.ToInt32(page.NotificationButton.First().Text);
            page.ApplyButton.Click();
            Assert.IsTrue(page.ConfirmBulkUpdate.Displayed);
            page.ProceedButton.Click();
            var count = 0;
            while (count < 30)
            {
                
                driver.WaitForAngularWithTimeout(1000);
                if (page.NotificationButton.Count == 1)
                {
                    var updatedNotificationCount = Convert.ToInt32(page.NotificationButton.First().Text);
                    if (updatedNotificationCount == notificationCount + 1)
                        break;
                }

                count++;
            }
            page.NotificationButton.First().Click();
            page.LatestBulkUpdateLink.Click();
            page.CaseLinkText.Click();
            StringAssert.DoesNotContain("TESTING",page.ReplaceTextInNamesGrid.Text);
            StringAssert.Contains(string.Empty,page.ReplaceTextInNamesGrid.Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CaseNameReferenceBulkUpdateForHierarchyNameType(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var ct = x.DbContext.Set<Country>().FirstOrDefault(_ => _.Id == "AU");
                var pt = x.DbContext.Set<PropertyType>().FirstOrDefault(_ => _.Code == "T");
                var @case = new CaseBuilder(x.DbContext).Create("1234/G", true, null, ct, pt);
                var nameType = x.DbContext.Set<NameType>().Where(_ => _.HierarchyFlag == 1 && _.PathNameType == "I");
                var name = x.DbContext.Set<Name>().FirstOrDefault();
                var caseName = new CaseName(@case, nameType.First(), name,0 ) {Reference = "TESTING"};
                x.DbContext.Set<CaseName>().Add(@caseName);
                x.DbContext.SaveChanges();

            });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkCaseNameReferenceUpdatePageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys("1234/G").Build().Perform();
            driver.WaitForAngular();
            page.SearchButton.Click();
            page.ResultsGrid.SelectRow(0);
            page.BulkOperationButton.Click();
            page.BulkUpdateButton.Click();
            page.NameTypeSelector.Click();
            page.InstructorNameType.Click();
            page.ReferenceText.SendKeys("Testing Reference");
            var notificationCount = 0;
            notificationCount = page.NotificationButton.Count==0 ? 0 : Convert.ToInt32(page.NotificationButton.First().Text);
            page.ApplyButton.Click();
            Assert.IsTrue(page.ConfirmBulkUpdate.Displayed);
            page.ProceedButton.Click();
            var count = 0;
            while (count < 30)
            {
                
                driver.WaitForAngularWithTimeout(1000);
                if (page.NotificationButton.Count == 1)
                {
                    var updatedNotificationCount = Convert.ToInt32(page.NotificationButton.First().Text);
                    if (updatedNotificationCount == notificationCount + 1)
                        break;
                }

                count++;
            }
            page.NotificationButton.First().Click();
            page.LatestBulkUpdateLink.Click();
            page.CaseLinkValue.Click();
            StringAssert.DoesNotContain("TESTING",page.ReplaceTextInNamesGrid.Text);
            StringAssert.Contains("Testing Reference",page.ReplaceTextInNamesGrid.Text);
            StringAssert.Contains("Testing Reference",page.ReplaceTextForHierarchyNameTypeInNamesGrid.Text);
        }
    }
}