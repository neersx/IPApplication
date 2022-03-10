using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Names;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.BulkCaseImport
{
    /* this test will access CPAInpro, if CPAInpro is not using the same database then the test will fail */

    [TestFixture]
    // [Property(RunnerOptions.Servers, RunnerOptions.ServersOptions.AustralianServers)]
    [Category(Categories.E2E)]
    public class MappingIssues : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void ViewMappingIssues(BrowserType browserType)
        {
            int batch;

            var driver = BrowserProvider.Get(browserType);

            var user = new Users().WithPermission(ApplicationTask.BulkCaseImport).Create();

            using (var setup = new MappingIssuesDbSetup())
            {
                var org = setup.NameBuilder.CreateClientOrg(RandomString.Next(5));
                var ind = setup.NameBuilder.CreateClientIndividual(RandomString.Next(5));
                batch = setup.CreateBatchWithMappingIssue(org, ind);
            }

            SignIn(driver, $"/#/bulkcaseimport/issues/mapping/{batch}", user.Username, user.Password);

            var mappingIssuesPage = new MappingIssuesPageObjects(driver);

            Assert.NotNull(mappingIssuesPage.BatchIdentifier, "should show batch summary link");

            Assert.NotNull(mappingIssuesPage.BatchSummaryLink);

            Assert.IsNotEmpty(mappingIssuesPage.MappingIssues, "should show mapping issues list");

            driver.ClickLinkToNewBrowserWindow(mappingIssuesPage.BatchSummaryLink);

            var url = driver.WithJs().GetUrl();

            Assert.True(url.Contains($"/#/bulkcaseimport/batchSummary/{batch}"), $"Clicking on the transaction link will take me to its batchSummary, but was {url}");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void ReviewImportStatusWithIssues(BrowserType browserType)
        {
            int batch;

            var driver = BrowserProvider.Get(browserType);

            var user = new Users().WithPermission(ApplicationTask.BulkCaseImport).Create();

            using (var setup = new MappingIssuesDbSetup())
            {
                var org = setup.NameBuilder.CreateClientOrg(RandomString.Next(5));
                var ind = setup.NameBuilder.CreateClientIndividual(RandomString.Next(5));
                batch = setup.CreateBatchWithMappingIssue(org, ind);
            }

            SignIn(driver, "/#/bulkcaseimport", user.Username, user.Password);

            KendoGrid importStatusGrid = new KendoGrid(driver, "importStatus");

            importStatusGrid.Grid.WithJs().ScrollIntoView();

            Assert.NotNull(importStatusGrid.Grid, "should show import status table");

            Assert.NotNull(importStatusGrid.Cell(0, 5).FindElement(By.TagName("a")), "should display the mapping issue link for the batch created above.");

            Assert.NotNull(importStatusGrid.Cell(0, 6).FindElement(By.TagName("a")), "should display the name issue link for the batch created above.");

            importStatusGrid.Cell(0, 6).FindElement(By.TagName("a")).Click();

            var url = driver.WithJs().GetUrl();

            Assert.True(url.Contains($"/#/bulkcaseimport/issues/name/{batch}"), $"should display name issues for the batch when it is clicked on, but was {url}");

            driver.With<NameIssuesPageObjects>(page =>
                                               {
                                                   Assert.NotNull(page.BatchIdentifier, "should show batch summary link");

                                                   Assert.NotNull(page.BatchSummaryLink);

                                                   Assert.IsNotEmpty(page.NameIssues, "should show name issues list");

                                                   Assert.IsNotEmpty(page.MapCandidates, "should show candidate matches for the first selected name");

                                                   driver.ClickLinkToNewBrowserWindow(page.BatchSummaryLink);

                                                   url = driver.WithJs().GetUrl();

                                                   Assert.True(url.Contains($"/#/bulkcaseimport/batchSummary/{batch}"), $"Clicking on the transaction link will take me to its batchSummary, but was {url}");
                                               });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void ResolveNameIssue(BrowserType browserType)
        {
            int batch;
            Name outsideName;

            var driver = BrowserProvider.Get(browserType);

            var user = new Users().WithPermission(ApplicationTask.BulkCaseImport).Create();

            using (var setup = new MappingIssuesDbSetup())
            {
                var names = setup.CreateNames();

                outsideName = setup.NameBuilder.CreateClientOrg(RandomString.Next(10) + "& $$@");

                batch = setup.CreateBatchWithMappingIssue(names.Org1, names.Ind1);
            }

            SignIn(driver, $"/#/bulkcaseimport/issues/name/{batch}", user.Username, user.Password);

            driver.With<NameIssuesPageObjects>(page =>
                                               {
                                                   page.SelectUnresolvedName(0);

                                                   var selectedNameCode = page.MapCandidateDetailsByBinding(0, "m.nameCode");
                                                   var selectedAddress = page.MapCandidateDetailsByBinding(0, "m.formattedAddress");

                                                   Assert.AreEqual(selectedNameCode, page.ComparisonPanel.ByField("Name Code").Selected, "Selected Map Candidate name code is displayed in ComparisonPanel");
                                                   Assert.AreEqual(selectedAddress, page.ComparisonPanel.ByField("Address").Selected, "Selected Map Candidate address is displayed in ComparisonPanel");
                                               });

            driver.With<NameIssuesPageObjects>(page =>
                                               {
                                                   var currentMapCandidatesCount = page.MapCandidates.Count;

                                                   page.SelectUnresolvedName(1);

                                                   Assert.AreNotEqual(currentMapCandidatesCount, page.MapCandidates.Count);

                                                   currentMapCandidatesCount = page.MapCandidates.Count;

                                                   var nameCodeForFirstCandidate = page.MapCandidateDetailsByBinding(0, "m.nameCode");

                                                   page.CandidateInput.Typeahead.SendKeys(outsideName.LastName);
                                                   page.CandidateInput.Typeahead.SendKeys(Keys.Tab);
                                                   page.CandidateInput.Typeahead.SendKeys(Keys.Tab);
                                                   
                                                   driver.Wait()
                                                         .ForTrue(() => page.CandidateInput.Typeahead.Text == string.Empty &&
                                                                        currentMapCandidatesCount + 1 == page.MapCandidates.Count, 60000); 

                                                   var firstRowNameCode = page.MapCandidateDetailsByBinding(0, "m.nameCode");
                                                   var firstRowRemarks = page.MapCandidateDetailsByBinding(0, "m.remarks");

                                                   Assert.AreNotEqual(nameCodeForFirstCandidate, firstRowNameCode, "Explicitly entered candidate should have been added as the first row in the candidate table");

                                                   Assert.AreEqual(firstRowNameCode, outsideName.NameCode, "The first row name code should be the same as the namecode that was entered");
                                                   Assert.AreEqual(firstRowRemarks, outsideName.Remarks, "The first row remarks should be that of the name selected");

                                                   page.CandidateInput.Typeahead.SendKeys(outsideName.NameCode);
                                                   page.CandidateInput.Typeahead.SendKeys(Keys.Tab);
                                                   page.CandidateInput.Typeahead.SendKeys(Keys.Tab);

                                                   driver.Wait().ForTrue(() => page.CandidateInput.Typeahead.Text == string.Empty); // auto complete should clear.

                                                   var nameCodeForSecondCandidate = page.MapCandidateDetailsByBinding(1, "m.nameCode");

                                                   Assert.AreNotEqual(nameCodeForSecondCandidate, firstRowNameCode, "Same explicitly entered candidate should not be entered.");

                                                   firstRowNameCode = page.MapCandidateDetailsByBinding(0, "m.nameCode");

                                                   Assert.AreEqual(firstRowNameCode, outsideName.NameCode, "The first row name code should be the same as the namecode that was entered");
                                               });
        }
    }
}