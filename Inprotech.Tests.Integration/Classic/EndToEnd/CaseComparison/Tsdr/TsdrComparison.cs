using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison.Extensions;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using Newtonsoft.Json;
using NUnit.Framework;
using OpenQA.Selenium;
using Case = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison.Tsdr
{
    [TestFixture]
    [Category(Categories.E2E)]
    [RebuildsIntegrationDatabase]
    public class TsdrComparison : IntegrationTest
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
        public void StandardComparisonScenario(BrowserType browserType)
        {
            var applicationNumber = RandomString.Next(20);
            var sessionGuid = Guid.NewGuid();

            var setup = new CaseComparisonDbSetup();
            var inprotechCase = setup.BuildInprotechCase("US", "T")
                                     .WithOfficialNumber(KnownNumberTypes.Application, applicationNumber);

            var originalCaseTitle = inprotechCase.Title;

            string fullPath;
            setup.BuildIntegrationEnvironment(DataSourceType.UsptoTsdr, sessionGuid)
                 .BuildIntegrationCase(DataSourceType.UsptoTsdr, inprotechCase.Id, applicationNumber)
                 .WithSuccessNotification(inprotechCase.Title)
                 .InStorage(sessionGuid, "cpa-xml.xml", out fullPath);

            CreateFileInStorage("uspto.tsdr.e2e-status.xml", "cpa-xml.xml", fullPath);

            var ken = new Users()
                .WithPermission(ApplicationTask.ViewCaseDataComparison)
                .WithPermission(ApplicationTask.SaveImportedCaseData)
                .Create();

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/casecomparison/inbox", ken.Username, ken.Password);

            driver.With<InboxPageObject>(page =>
                                         {
                                             Assert.AreEqual(1, page.Notifications.Count, "Should have a single notification.");

                                             Assert.IsTrue(page.CaseComparisonView.IsDisplayed(), "Should display case comparison view.");

                                             Assert.IsTrue(page.CaseComparisonView.OfficialNumbers.Displayed, "Should contain some official numbers");

                                             Assert.IsNotEmpty(page.CaseComparisonView.CaseNames, "Should contain some names");

                                             Assert.IsNotEmpty(page.CaseComparisonView.Events, "Should contain some events");

                                             Assert.IsNotEmpty(page.CaseComparisonView.GoodsServices, "Should contain some goods and services");

                                             Assert.IsTrue(page.CaseComparisonView.UpdateCase.IsVisible(), "Should have the 'Update Case' button as it is not readonly");

                                             Assert.IsTrue(page.CaseComparisonView.MarkReviewed.IsVisible(), "Should have the 'Mark Review' button as it is not readonly");

                                             Assert.IsTrue(page.CaseComparisonView.UpdateCase.IsDisabled(), "Should have the 'Update Case' button disabled initially");

                                             Assert.IsFalse(page.CaseComparisonView.MarkReviewed.IsDisabled(), "Should have the 'Mark Review' button enabled all the time");
                                         });

            driver.With<InboxPageObject>(page =>
                                         {

                                             // Can Identify Parse Error.

                                             foreach (var firstUseParseErrors in page.CaseComparisonView.GoodsServices[2].FindElements(By.CssSelector(".parse-error")))
                                             {
                                                 var errorsFromTsdr = new[]
                                                                      {
                                                                          "2130601", "2131204"
                                                                      };

                                                 Assert.True(errorsFromTsdr.Any(baddate => firstUseParseErrors.Text.IndexOf(baddate, StringComparison.OrdinalIgnoreCase) > -1));
                                             }
                                             
                                             // update case

                                             page.CaseComparisonView.Title.Click();

                                             page.CaseComparisonView.Update();
                                         });

            DbSetup.Do(x =>
                       {
                           var updatedCase = x.DbContext.Set<Case>().Single(_ => _.Id == inprotechCase.Id);
                           Assert.AreNotEqual(originalCaseTitle, updatedCase.Title, "Should not have the same title as it has been updated.");

                           Assert.AreEqual("IPAD", updatedCase.Title, "Should have the updated case title from status.xml");
                       });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DocumentsAndDmsIntegration(BrowserType browserType)
        {
            var applicationNumber = RandomString.Next(20);
            var sessionGuid = Guid.NewGuid();

            var setup = new CaseComparisonDbSetup();
            var inprotechCase = setup.BuildInprotechCase("US", "T")
                                     .WithOfficialNumber(KnownNumberTypes.Application, applicationNumber);

            string fullPath;
            setup.BuildIntegrationEnvironment(DataSourceType.UsptoTsdr, sessionGuid)
                 .BuildIntegrationCase(DataSourceType.UsptoTsdr, inprotechCase.Id, applicationNumber)
                 .WithSuccessNotification(inprotechCase.Title)
                 .InStorage(sessionGuid, "cpa-xml.xml", out fullPath)
                 .WithDmsEnabled();

            CreateFileInStorage("uspto.tsdr.e2e-status.xml", "cpa-xml.xml", fullPath);

            var ken = new Users()
                .WithPermission(ApplicationTask.ViewCaseDataComparison)
                .WithPermission(ApplicationTask.SaveImportedCaseData)
                .Create();

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/casecomparison/inbox", ken.Username, ken.Password);

            var documents = IntegrationDbSetup.Do(db =>
                                                  {
                                                      var doc1 = db.Insert(new Document
                                                                           {
                                                                               ApplicationNumber = applicationNumber,
                                                                               Status = DocumentDownloadStatus.Downloaded,
                                                                               MailRoomDate = DateTime.Today,
                                                                               Source = DataSourceType.UsptoTsdr,
                                                                               FileWrapperDocumentCode = "A",
                                                                               DocumentDescription = RandomString.Next(10)
                                                                           }.WithDefaults());

                                                      var doc2 = db.Insert(new Document
                                                                           {
                                                                               ApplicationNumber = applicationNumber,
                                                                               Status = DocumentDownloadStatus.FailedToSendToDms,
                                                                               MailRoomDate = DateTime.Today.AddDays(-1),
                                                                               Errors = JsonConvert.SerializeObject("error: failed to send"),
                                                                               Source = DataSourceType.UsptoTsdr,
                                                                               FileWrapperDocumentCode = "B",
                                                                               DocumentDescription = RandomString.Next(10)
                                                                           }.WithDefaults());
                                                      return new
                                                             {
                                                                 doc1,
                                                                 doc2
                                                             };
                                                  });

            driver.With<InboxPageObject>(page =>
                                         {
                                             page.Notifications[0].Click(); // reload;

                                             var docs = page.CaseComparisonView.AllDocumentSummary<TsdrDocumentSummary>().ToArray();

                                             Assert.AreEqual(documents.doc1.DocumentCategory, docs[0].DocumentCode);

                                             Assert.AreEqual(documents.doc1.DocumentDescription, docs[0].DocumentDescription);

                                             Assert.AreEqual("Downloaded", docs[0].Status, "Should have 'Downloaded Status'");

                                             Assert.True(docs[0].HasDownloadLink, "Should have download link");

                                             Assert.AreEqual(documents.doc2.DocumentCategory, docs[1].DocumentCode);

                                             Assert.AreEqual(documents.doc2.DocumentDescription, docs[1].DocumentDescription);

                                             Assert.AreEqual("DMS Error", docs[1].Status, "Should have 'Downloaded Status'");

                                             Assert.True(docs[0].HasDownloadLink, "Should have download link");

                                             page.CaseComparisonView.DisplayErrorDetailsDialog();

                                             Assert.IsTrue(page.CaseComparisonView.ErrorDetailsDialog.IsVisible(), "Should display error details dialog");

                                             page.CaseComparisonView.DismissErrorDetailsDialog();

                                             page.CaseComparisonView.MoveAllToDms.Click();

                                             docs = page.CaseComparisonView.AllDocumentSummary<TsdrDocumentSummary>().ToArray();

                                             Assert.IsTrue(docs.All(_ => !_.HasDownloadLink), "Should not longer have download links");

                                             Assert.IsTrue(docs.All(_ => _.Status == "Moving to DMS"), "Should all have status of 'Moving to DMS");
                                         });
        }

        void CreateFileInStorage(string file, string name, string fullPath)
        {
            var filePath = FileSetup.SendToStorage(file, name, fullPath.Replace(name, string.Empty));

            _filesAdded.Add(filePath);
        }
    }
}