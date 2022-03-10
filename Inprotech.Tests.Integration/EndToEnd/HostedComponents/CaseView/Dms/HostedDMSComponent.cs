using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.Dms;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Names;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.Dms
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedDmsComponent : IntegrationTest
    {
        Case Setup()
        {
            Case case1 = null;
            DbSetup.Do(db =>
            {
                case1 = new CaseBuilder(db.DbContext).Create(Fixture.String(5) + "1", true);
                new ScreenCriteriaBuilder(db.DbContext).Create(case1, out _)
                                                       .WithTopicControl(KnownCaseScreenTopics.CaseHeader)
                                                       .WithTopicControl(KnownCaseScreenTopics.Dms);

                new DocumentManagementDbSetup().Setup();
                db.DbContext.SaveChanges();
            });
            return case1;
        }

        Name SetupName()
        {
            Name name = null;

            DbSetup.Do(db =>
            {
                name = new NameBuilder(db.DbContext).CreateOrg(NameUsedAs.Organisation, "homeOrg");
                new ScreenCriteriaBuilder(db.DbContext).CreateNameScreen(name, out _)
                                                       .WithTopicControl(KnownNamePrograms.NameEntry)
                                                       .WithTopicControl(KnownNameScreenTopics.Dms);
                new DocumentManagementDbSetup().Setup();
                db.DbContext.SaveChanges();
            });
            return name;
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedDmsLifecycle(BrowserType browserType)
        {
            var thisCase = Setup();
            var user = new Users()
                       .WithLicense(LicensedModule.CasesAndNames)
                       .WithPermission(ApplicationTask.AccessDocumentsfromDms)
                       .Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test", user.Username, user.Password);
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case View DMS";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(thisCase.Irn);
            driver.WaitForAngular();

            page.ProgramPicklist.SelectItem(KnownCasePrograms.CaseEntry);
            driver.WaitForAngular();

            page.CaseSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var hostedDmsTopic = new CaseDmsTopic(driver);
                Assert.IsNotEmpty(hostedDmsTopic.DirectoryTreeView.Folders);
                Assert.True(hostedDmsTopic.DirectoryTreeView.Folders.First().FolderIcon.IndexOf("cpa-icon-workspace", StringComparison.Ordinal) > -1);

                Assert.True(hostedDmsTopic.DirectoryTreeView.Folders.First().Children.Single(fn => fn.Name.Trim() == "Email").FolderIcon.IndexOf("cpa-icon-envelope", StringComparison.Ordinal) > -1);
                Assert.AreEqual(true, hostedDmsTopic.DirectoryTreeView.Folders.First().Children.Single(fn => fn.Name.Trim() == "Correspondence").IsParent);
                Assert.True(hostedDmsTopic.DirectoryTreeView.Folders.First().Children.First().FolderIcon.IndexOf("cpa-icon-folder", StringComparison.Ordinal) > -1);

                hostedDmsTopic.DirectoryTreeView.Folders[0].Children[0].Click();
                Assert.IsNotEmpty(hostedDmsTopic.Documents.Rows);
                Assert.AreEqual(1, hostedDmsTopic.Documents.Cell(0, 1).FindElements(By.ClassName("cpa-icon-envelope")).Count);
                Assert.AreEqual(1, hostedDmsTopic.Documents.Cell(0, 2).FindElements(By.ClassName("cpa-icon-paperclip")).Count);
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedNameDmsLifecycle(BrowserType browserType)
        {
            var thisName = SetupName();
            var user = new Users()
                       .WithLicense(LicensedModule.CasesAndNames)
                       .WithPermission(ApplicationTask.AccessDocumentsfromDms)
                       .Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test", user.Username, user.Password);
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Name View DMS";
            driver.WaitForAngular();

            page.NamePicklist.SelectItem(thisName.NameCode);
            driver.WaitForAngular();

            page.NameSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var hostedDmsTopic = new NameDmsTopic(driver);
                Assert.IsNotEmpty(hostedDmsTopic.DirectoryTreeView.Folders);
                Assert.True(hostedDmsTopic.DirectoryTreeView.Folders.First().FolderIcon.IndexOf("cpa-icon-workspace", StringComparison.Ordinal) > -1);

                Assert.True(hostedDmsTopic.DirectoryTreeView.Folders.First().Children.Single(fn => fn.Name.Trim() == "Email").FolderIcon.IndexOf("cpa-icon-envelope", StringComparison.Ordinal) > -1);
                Assert.AreEqual(true, hostedDmsTopic.DirectoryTreeView.Folders.First().Children.Single(fn => fn.Name.Trim() == "Correspondence").IsParent);
                Assert.True(hostedDmsTopic.DirectoryTreeView.Folders.First().Children.First().FolderIcon.IndexOf("cpa-icon-folder", StringComparison.Ordinal) > -1);

                hostedDmsTopic.DirectoryTreeView.Folders[0].Children[0].Click();
                Assert.IsNotEmpty(hostedDmsTopic.Documents.Rows);
                Assert.AreEqual(1, hostedDmsTopic.Documents.Cell(0, 1).FindElements(By.ClassName("cpa-icon-envelope")).Count);
                Assert.AreEqual(1, hostedDmsTopic.Documents.Cell(0, 2).FindElements(By.ClassName("cpa-icon-paperclip")).Count);
            });
        }
    }
}