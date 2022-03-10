using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.Dms;
using Inprotech.Tests.Integration.EndToEnd.Search;
using Inprotech.Tests.Integration.EndToEnd.Search.Case;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Integration.DocumentManagement
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseDocumentManagementLinks : IntegrationTest
    {
        static dynamic CreateCase()
        {
            return DbSetup.Do(x =>
            {
                var irnPrefix = "tasks_case";

                var c = new CaseBuilder(x.DbContext).Create(irnPrefix);

                return new
                {
                    CasePrefix = irnPrefix,
                    CaseIrn = c.Irn,
                    Case = c
                };
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void VerifyDocumentManagementDownloadLinkIsIwl(BrowserType browserType)
        {
            var @case = CreateCase();
            new DocumentManagementDbSetup().Setup();
            var internalUser = new Users().WithPermission(ApplicationTask.AccessDocumentsfromDms).Create();
            DbSetup.Do(x =>
            {
                var u = x.DbContext.Set<User>().Single(_ => _.Id == internalUser.Id);

                x.Insert(new SettingValues
                {
                    BooleanValue = true,
                    User = u,
                    SettingId = KnownSettingIds.UseImanageWorkLink
                });
            });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/search-result?queryContext=2&q={@case.CasePrefix}", internalUser.Username, internalUser.Password);

            var searchResultPageObject = new SearchPageObject(driver);
            searchResultPageObject.TaskMenuButton().Click();

            driver.WaitForAngular();
            WaitHelper.Wait(1000);
            Assert.IsFalse(searchResultPageObject.OpenDmsMenu.IsDisabled());
            searchResultPageObject.OpenDmsMenu.Click();
            driver.WaitForAngular();
            WaitHelper.Wait(1000);
            
            driver.With<DocumentManagementPageObject>(page =>
            {
                var documentManagementPage = new DocumentManagementPageObject(driver);
                driver.Wait().ForTrue(() => documentManagementPage.DirectoryTreeView.Folders.Count != 0, 20000);

                documentManagementPage.DirectoryTreeView.Folders.First().Click();
                Assert.True(page.OpenIniManageLink.IsVisible());
                Assert.False(page.OpenIniManageLink.IsDisabled());
                var documentsGrid = page.Documents;
                driver.WaitForAngular();

                var href = documentsGrid.Cell(0, 3)
                                        .FindElement(By.TagName("a")).GetAttribute("href");

                Assert.AreEqual("iwl:dms=sdksandbox.goimanage.com&&lib=TPSDK&&num=96053&&ver=1", href);
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void VerifyDocumentManagementDownloadLinkIsNotIwl(BrowserType browserType)
        {
            var @case = CreateCase();
            new DocumentManagementDbSetup().Setup();
            var internalUser = new Users().WithPermission(ApplicationTask.AccessDocumentsfromDms).Create();
            DbSetup.Do(x =>
            {
                var u = x.DbContext.Set<User>().Single(_ => _.Id == internalUser.Id);

                x.Insert(new SettingValues
                {
                    BooleanValue = false,
                    User = u,
                    SettingId = KnownSettingIds.UseImanageWorkLink
                });
            });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/search-result?queryContext=2&q={@case.CasePrefix}", internalUser.Username, internalUser.Password);

            var searchResultPageObject = new SearchPageObject(driver);
            searchResultPageObject.TaskMenuButton().Click();

            driver.WaitForAngular();
            WaitHelper.Wait(1000);
            Assert.IsFalse(searchResultPageObject.OpenDmsMenu.IsDisabled());
            searchResultPageObject.OpenDmsMenu.Click();
            driver.WaitForAngular();
            WaitHelper.Wait(1000);

            driver.With<DocumentManagementPageObject>(page =>
            {
                var documentManagementPage = new DocumentManagementPageObject(driver);
                driver.Wait().ForTrue(() => documentManagementPage.DirectoryTreeView.Folders.Count != 0, 20000);
                var documentsGrid = page.Documents;
                driver.WaitForAngular();

                var href = documentsGrid.Cell(0, 3)
                                        .FindElement(By.TagName("a")).GetAttribute("href");

                Assert.True(href.Contains("/apps/api/document-management/download/0-TPSDK!96053.1"));
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyDocumentManagementTaskOptionDoesNotShowIfNoPermission(BrowserType browserType)
        {
            var @case = CreateCase();
            new DocumentManagementDbSetup().Setup();
            var internalUser = new Users().Create();
            DbSetup.Do(x =>
            {
                var u = x.DbContext.Set<User>().Single(_ => _.Id == internalUser.Id);

                x.Insert(new SettingValues
                {
                    BooleanValue = false,
                    User = u,
                    SettingId = KnownSettingIds.UseImanageWorkLink
                });
            });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/search-result?queryContext=2&q={@case.CasePrefix}", internalUser.Username, internalUser.Password);

            var searchResultPageObject = new SearchPageObject(driver);
            Assert.IsFalse(searchResultPageObject.TaskMenuButton().IsDisabled());
            searchResultPageObject.TaskMenuButton().Click();

            driver.WaitForAngular();
            WaitHelper.Wait(1000);
            Assert.Throws<NoSuchElementException>(() => searchResultPageObject.OpenDmsMenu.IsDisabled());
        }
    }
}