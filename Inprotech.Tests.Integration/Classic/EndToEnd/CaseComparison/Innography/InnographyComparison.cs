using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison.Extensions;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Integration;
using NUnit.Framework;
using OpenQA.Selenium;
using Case = InprotechKaizen.Model.Cases.Case;
using Inbox = Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison.InboxPageObject;
using DuplicatesView = Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison.DuplicatesPageObject;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison.Innography
{
    [TestFixture]
    [Category(Categories.E2E)]
    [RebuildsIntegrationDatabase]
    public class InnographyComparison : IntegrationTest
    {
        [TearDown]
        public void CleanupFiles()
        {
            foreach (var file in _filesAdded)
                FileSetup.DeleteFile(file);
        }

        readonly List<string> _filesAdded = new List<string>();

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void StandardComparisonScenarioForPatent(BrowserType browserType)
        {
            var applicationNumber = RandomString.Next(20);
            var sessionGuid = Guid.NewGuid();

            var setup = new CaseComparisonDbSetup();
            var inprotechCase = setup.BuildInprotechCase("US", "P")
                                     .WithOfficialNumber(KnownNumberTypes.Application, applicationNumber);

            var originalCaseTitle = inprotechCase.Title;

            setup.BuildIntegrationEnvironment(DataSourceType.IpOneData, sessionGuid)
                 .BuildIntegrationCase(DataSourceType.IpOneData, inprotechCase.Id, applicationNumber)
                 .WithSuccessNotification(inprotechCase.Title)
                 .InStorage(sessionGuid, "cpa-xml.xml", out string fullPath);

            CreateFileInStorage("innography.cpa-xml.xml", "cpa-xml.xml", fullPath);

            var ken = new Users()
                .WithPermission(ApplicationTask.ViewCaseDataComparison)
                .WithPermission(ApplicationTask.SaveImportedCaseData)
                .Create();

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/casecomparison/inbox", ken.Username, ken.Password);

            driver.With<Inbox>(page =>
                               {
                                   Assert.AreEqual(1, page.Notifications.Count, "Should have a single notification.");

                                   Assert.IsTrue(page.CaseComparisonView.IsDisplayed(), "Should display case comparison view.");

                                   Assert.IsTrue(page.CaseComparisonView.OfficialNumbers.Displayed, "Should contain some official numbers");

                                   Assert.IsNotEmpty(page.CaseComparisonView.CaseNames, "Should contain some names");

                                   Assert.IsTrue(page.CaseComparisonView.UpdateCase.IsVisible(), "Should have the 'Update Case' button as it is not readonly");

                                   Assert.IsTrue(page.CaseComparisonView.MarkReviewed.IsVisible(), "Should have the 'Mark Review' button as it is not readonly");

                                   Assert.IsTrue(page.CaseComparisonView.UpdateCase.IsDisabled(), "Should have the 'Update Case' button disabled initially");

                                   Assert.IsFalse(page.CaseComparisonView.MarkReviewed.IsDisabled(), "Should have the 'Mark Review' button enabled all the time");

                                   // update case

                                   page.CaseComparisonView.Title.Click();

                                   page.CaseComparisonView.Update();
                               });

            DbSetup.Do(x =>
                       {
                           var updatedCase = x.DbContext.Set<Case>().Single(_ => _.Id == inprotechCase.Id);
                           Assert.AreNotEqual(originalCaseTitle, updatedCase.Title, "Should not have the same title as it has been updated.");

                           Assert.AreEqual("ION GUIDE ARRAY", updatedCase.Title, "Should have the updated case title from status.xml");

                           var cpaglobalIdentifier = x.DbContext.Set<CpaGlobalIdentifier>().Single(_ => _.CaseId == inprotechCase.Id);
                           Assert.AreEqual("I-000096327031", cpaglobalIdentifier.InnographyId, "Should set the innography Id from cpa-xml against the case");
                           Assert.AreEqual(true, cpaglobalIdentifier.IsActive, "Should set the innography Id link as being 'Active'.");
                       });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void RejectTheCaseMatchThenResetTheRejection(BrowserType browserType)
        {
            var applicationNumber = RandomString.Next(20);
            var sessionGuid = Guid.NewGuid();

            var setup = new CaseComparisonDbSetup();
            var inprotechCase = setup.BuildInprotechCase("US", "P")
                                     .WithOfficialNumber(KnownNumberTypes.Application, applicationNumber);
            
            setup.BuildIntegrationEnvironment(DataSourceType.IpOneData, sessionGuid)
                 .BuildIntegrationCase(DataSourceType.IpOneData, inprotechCase.Id, applicationNumber)
                 .WithSuccessNotification(inprotechCase.Title)
                 .InStorage(sessionGuid, "cpa-xml.xml", out string fullPath);

            CreateFileInStorage("innography.cpa-xml.xml", "cpa-xml.xml", fullPath);

            var ken = new Users()
                .WithPermission(ApplicationTask.ViewCaseDataComparison)
                .WithPermission(ApplicationTask.SaveImportedCaseData)
                .Create();

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/casecomparison/inbox", ken.Username, ken.Password);

            driver.With<Inbox>(page =>
                               {
                                   Assert.AreEqual(1, page.Notifications.Count, "Should have a single notification.");

                                   Assert.IsTrue(page.CaseComparisonView.IsDisplayed(), "Should display case comparison view.");

                                   Assert.IsTrue(page.CaseComparisonView.OfficialNumbers.Displayed, "Should contain some official numbers");

                                   Assert.IsNotEmpty(page.CaseComparisonView.CaseNames, "Should contain some names");

                                   Assert.True(page.CaseComparisonView.HasSelectableDiffs, "Should have differences that can be selected for import");

                                   Assert.IsTrue(page.CaseComparisonView.UpdateCase.IsVisible(), "Should have the 'Update Case' button as it is not readonly");

                                   Assert.IsTrue(page.CaseComparisonView.MarkReviewed.IsVisible(), "Should have the 'Mark Review' button as it is not readonly");

                                   Assert.IsTrue(page.CaseComparisonView.UpdateCase.IsDisabled(), "Should have the 'Update Case' button disabled initially");

                                   Assert.IsFalse(page.CaseComparisonView.MarkReviewed.IsDisabled(), "Should have the 'Mark Review' button enabled all the time");
                               });

            driver.With<Inbox>(page =>
                               {
                                   // Included rejected items
                                   page.IncludeRejected.Click();

                                   page.CaseComparisonView.WaitUntilLoaded();

                                   page.CaseComparisonView.RejectMatch();

                                   page.CaseComparisonView.WaitUntilLoaded();

                                   Assert.NotNull(page.CaseComparisonView.RejectedMatchNotice, "Should display the rejected match notice.");

                                   Assert.False(page.CaseComparisonView.HasSelectableDiffs, "Should not allow any differences to be selected in Rejected state");
                               });

            DbSetup.Do(x =>
                       {
                           var cpaglobalIdentifier = x.DbContext.Set<CpaGlobalIdentifier>().Single(_ => _.CaseId == inprotechCase.Id);
                           Assert.AreEqual("I-000096327031", cpaglobalIdentifier.InnographyId, "Should set the innography Id from cpa-xml against the case");
                           Assert.AreEqual(false, cpaglobalIdentifier.IsActive, "Should set the innography Id link as being 'Inactive'.");
                       });

            driver.With<Inbox>(page =>
                               {
                                   page.CaseComparisonView.UndoMatchRejection();

                                   page.CaseComparisonView.WaitUntilLoaded();

                                   Assert.True(page.CaseComparisonView.HasSelectableDiffs, "Should allow differences to be selected after reverting from Rejected state");
                               });

            DbSetup.Do(x =>
                       {
                           var cpaglobalIdentifierExist = x.DbContext.Set<CpaGlobalIdentifier>().Any(_ => _.CaseId == inprotechCase.Id);
                           Assert.AreEqual(false, cpaglobalIdentifierExist, "The innography link is cleared.");
                       });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DisplayDuplicateMatchesAndNavigateBack(BrowserType browserType)
        {
            const string innographyId = "I-000096327031";

            var inprotechCaseToConsider = CreateNotificationWithCase(RandomString.Next(20), "cpa-xml2.xml");

            var inprotechCase = CreateNotificationWithCase(RandomString.Next(20), "cpa-xml1.xml");
            inprotechCase.LinkInnographyId(innographyId);

            var ken = new Users()
                .WithPermission(ApplicationTask.ViewCaseDataComparison)
                .WithPermission(ApplicationTask.SaveImportedCaseData)
                .Create();

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/casecomparison/inbox", ken.Username, ken.Password);

            driver.With<Inbox>(page =>
            {
                page.IncludeReviewed.Click();

                page.Notifications.Last().Click();

                Assert.AreEqual(2, page.Notifications.Count, "Should have two notifications.");

                page.CaseComparisonView.WaitUntilLoaded();

                Assert.NotNull(page.CaseComparisonView.DuplicateMatchNotice, "Duplicate notice is displayed");

                page.CaseComparisonView.NavigateToDuplicateLink.Click();
            });

            driver.With<DuplicatesView>(page =>
            {
                Assert.AreEqual(2, page.Notifications.Count, "Should have two notifications in duplicates view.");
                
                Assert.NotNull(page.CaseComparisonView.CaseRefLink(inprotechCaseToConsider.Irn));

                page.CaseComparisonView.MarkReviewed.Click();

                driver.WaitForAngular();

                page.NavigateBackToInbox.ClickWithTimeout();
            });

            driver.With<Inbox>(page =>
            {
                Assert.AreEqual(2, page.Notifications.Count, "Should have two notifications.");

                page.IncludeReviewed.Click();

                Assert.AreEqual(1, page.Notifications.Count, "Should hide reviewed notification.");
            });

            DbSetup.Do(x =>
            {
                var cpaglobalIdentifierCount = x.DbContext.Set<CpaGlobalIdentifier>().Count(_ => _.InnographyId == innographyId);
                Assert.AreEqual(2, cpaglobalIdentifierCount);
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void StandardComparisonScenarioForTrademark(BrowserType browserType)
        {
            var applicationNumber = RandomString.Next(20);
            var sessionGuid = Guid.NewGuid();

            var setup = new CaseComparisonDbSetup();
            var inprotechCase = setup.BuildInprotechCase("US", "T")
                                     .WithOfficialNumber(KnownNumberTypes.Application, applicationNumber);

            var originalCaseTitle = inprotechCase.Title;
            var originalTypeOfMark = inprotechCase.TypeOfMark?.Name;
            var originalGsText = inprotechCase.CaseTexts.FirstOrDefault()?.Text;

            setup.BuildIntegrationEnvironment(DataSourceType.IpOneData, sessionGuid)
                 .BuildIntegrationCase(DataSourceType.IpOneData, inprotechCase.Id, applicationNumber)
                 .WithSuccessNotification(inprotechCase.Title)
                 .InStorage(sessionGuid, "cpa-xml.xml", out string fullPath);

            CreateFileInStorage("innography.trademark.cpa-xml.xml", "cpa-xml.xml", fullPath);

            var ken = new Users()
                .WithPermission(ApplicationTask.ViewCaseDataComparison)
                .WithPermission(ApplicationTask.SaveImportedCaseData)
                .Create();

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/casecomparison/inbox", ken.Username, ken.Password);

            driver.With<Inbox>(page =>
                               {
                                   Assert.AreEqual(1, page.Notifications.Count, "Should have a single notification.");

                                   Assert.IsTrue(page.CaseComparisonView.IsDisplayed(), "Should display case comparison view.");

                                   Assert.IsTrue(page.CaseComparisonView.OfficialNumbers.Displayed, "Should contain some official numbers");

                                   Assert.IsNotEmpty(page.CaseComparisonView.CaseNames, "Should contain some names");

                                   Assert.IsTrue(page.CaseComparisonView.UpdateCase.IsVisible(), "Should have the 'Update Case' button as it is not readonly");

                                   Assert.IsTrue(page.CaseComparisonView.MarkReviewed.IsVisible(), "Should have the 'Mark Review' button as it is not readonly");

                                   Assert.IsTrue(page.CaseComparisonView.UpdateCase.IsDisabled(), "Should have the 'Update Case' button disabled initially");

                                   Assert.IsFalse(page.CaseComparisonView.MarkReviewed.IsDisabled(), "Should have the 'Mark Review' button enabled all the time");

                                   // update case
                                   page.CaseComparisonView.Title.Click();
                                   page.CaseComparisonView.TypeOfMark.Click();
                                   Assert.True(page.CaseComparisonView.GoodsServices.Any());
                                   page.CaseComparisonView.GoodsServices.AsEnumerable().First().FindElement(By.ClassName("diff")).Click();
                                   page.CaseComparisonView.Update();
                               });

            DbSetup.Do(x =>
                       {
                           var updatedCase = x.DbContext.Set<Case>().Single(_ => _.Id == inprotechCase.Id);
                           Assert.AreNotEqual(originalCaseTitle, updatedCase.Title, "Should not have the same title as it has been updated.");
                           Assert.AreNotEqual(originalTypeOfMark, updatedCase.TypeOfMark?.Name, "Should not have the same type of mark as it has been updated.");
                           Assert.AreEqual("ION GUIDE ARRAY", updatedCase.Title, "Should have the updated case title from status.xml");
                           Assert.AreNotEqual(originalGsText, updatedCase.CaseTexts.FirstOrDefault()?.Text, "(1) Water heating units.");
                           var cpaglobalIdentifier = x.DbContext.Set<CpaGlobalIdentifier>().Single(_ => _.CaseId == inprotechCase.Id);
                           Assert.AreEqual("T-000096327031", cpaglobalIdentifier.InnographyId, "Should set the innography Id from cpa-xml against the case");
                           Assert.AreEqual(true, cpaglobalIdentifier.IsActive, "Should set the innography Id link as being 'Active'.");
                       });
        }

        Case CreateNotificationWithCase(string applicationNumber, string xmlName)
        {
            var setup = new CaseComparisonDbSetup();
            var sessionGuid = Guid.NewGuid();
            
            var inprotechCase = setup.BuildInprotechCase("US", "P")
                                      .WithOfficialNumber(KnownNumberTypes.Application, applicationNumber);
            setup.BuildIntegrationEnvironment(DataSourceType.IpOneData, sessionGuid)
                 .BuildIntegrationCase(DataSourceType.IpOneData, inprotechCase.Id, applicationNumber)
                 .WithSuccessNotification(inprotechCase.Title)
                 .InStorage(sessionGuid, xmlName, out string fullPath1);
            CreateFileInStorage("innography.cpa-xml.xml", xmlName, fullPath1);

            return inprotechCase;
        }

        void CreateFileInStorage(string file, string name, string fullPath)
        {
            var filePath = FileSetup.SendToStorage(file, name, fullPath.Replace(name, string.Empty));

            _filesAdded.Add(filePath);
        }
    }
}