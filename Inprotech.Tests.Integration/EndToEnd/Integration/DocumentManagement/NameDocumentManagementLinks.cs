using System;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.Dms;
using Inprotech.Tests.Integration.EndToEnd.Search;
using Inprotech.Tests.Integration.EndToEnd.Search.Case;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Integration.DocumentManagement
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release15)]
    public class NameDocumentManagementLinks : IntegrationTest
    {
        string _originalCaseSearchSiteControl;
        string _originalNameSearchSiteControl;

        readonly string[] _siteControlsKeys = 
        {
            SiteControls.DMSCaseSearchDocItem,
            SiteControls.DMSNameSearchDocItem
        };
        const string DocItemName = "e2e name search doc item";

        [SetUp]
        public void Setup()
        {
            using (var db = new DbSetup())
            {
                var siteControls = db.DbContext.Set<SiteControl>().Where(_ => _siteControlsKeys.Contains(_.ControlId)).ToArray();
                _originalCaseSearchSiteControl = siteControls.Single(_ => _.ControlId == SiteControls.DMSCaseSearchDocItem).StringValue;
                _originalNameSearchSiteControl = siteControls.Single(_ => _.ControlId == SiteControls.DMSNameSearchDocItem).StringValue;
                db.InsertWithNewId(new DocItem
                {
                    Name = DocItemName,
                    Description = "e2e - DataItem",
                    ItemType = 0,
                    Sql = "select SUBSTRING(NAMECODE, PATINDEX('%[^0]%', NAMECODE+'.'), LEN(NAMECODE)) from NAME where NAMECODE = :gstrEntryPoint",
                    DateUpdated = DateTime.Now,
                    DateCreated = DateTime.Now,
                    CreatedBy = "e2e - UpdatedBy"
                });
                siteControls.Single(_ => _.ControlId == SiteControls.DMSNameSearchDocItem).StringValue = DocItemName;
                db.DbContext.SaveChanges();
            }
        }

        [TearDown]
        public void Cleanup()
        {
            using (var db = new DbSetup())
            {
                var siteControls = db.DbContext.Set<SiteControl>().Where(_ => _siteControlsKeys.Contains(_.ControlId)).ToArray();

                var caseSearch = siteControls.Single(_ => _.ControlId == SiteControls.DMSCaseSearchDocItem);
                if (_originalCaseSearchSiteControl != caseSearch.StringValue) caseSearch.StringValue = _originalCaseSearchSiteControl;

                var nameSearch = siteControls.Single(_ => _.ControlId == SiteControls.DMSNameSearchDocItem);
                if (_originalNameSearchSiteControl != nameSearch.StringValue) nameSearch.StringValue = _originalNameSearchSiteControl;
                db.Delete(db.DbContext.Set<DocItem>().First(_ => _.Name == DocItemName));
                db.DbContext.SaveChanges();
            }
        }

        static dynamic CreateName()
        {
            return DbSetup.Do(x =>
            {
                var irnPrefix = "tasks_name";

                var n = new NameBuilder(x.DbContext).Create(irnPrefix);
                n.NameCode = Fixture.String(5);
                x.DbContext.SaveChanges();
                return new
                {
                    NamePrefix = irnPrefix,
                    Name = n
                };
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void VerifyDocumentManagementDownloadLinkIsIwl(BrowserType browserType)
        {
            var name = CreateName();
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
            SignIn(driver, $"/#/search-result?queryContext=10&q={name.NamePrefix}", internalUser.Username, internalUser.Password);

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
            var name = CreateName();
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
            SignIn(driver, $"/#/search-result?queryContext=10&q={name.NamePrefix}", internalUser.Username, internalUser.Password);

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
            var name = CreateName();
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
            SignIn(driver, $"/#/search-result?queryContext=10&q={name.NamePrefix}", internalUser.Username, internalUser.Password);

            var searchResultPageObject = new SearchPageObject(driver);
            Assert.True(searchResultPageObject.TaskMenuButton().IsDisabled());
        }
    }
}