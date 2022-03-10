using System;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.AuditTrail;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Ede;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.BulkCaseImport
{
    [TestFixture]
    [Category(Categories.E2E)]
    public class ImportStatus : IntegrationTest
    {
        [TearDown]
        public void TearDown()
        {
            if (_loggingSetOn)
            {
                new ReverseBatchDbSetup().TurnOffLoggingForCases();
                _loggingSetOn = false;
            }
        }

        bool _loggingSetOn;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void ViewBatchSummaryFromImportStatus(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            var user = new Users().WithPermission(ApplicationTask.BulkCaseImport).Create();

            var batchData = new ViewBatchSummaryDbSetup().CreateBatch();

            var batch = batchData.Item1;

            var batchFigures = batchData.Item2;

            SignIn(driver, "/#/bulkcaseimport", user.Username, user.Password);

            var importStatusGrid = new KendoGrid(driver, "importStatus");
            var statusFilter = new MultiSelectGridFilter(driver, "importStatus", "displayStatusType");

            importStatusGrid.Grid.WithJs().ScrollIntoView();

            Assert.AreEqual(batchFigures["total"].ToString(), importStatusGrid.Cell(0, 0).Text, $"should contain {batchFigures["total"]} transactions in total");
            statusFilter.Open();
            statusFilter.SelectOption(importStatusGrid.LockedCellText(0, 1));
            statusFilter.Filter();
            Assert.AreEqual(1, importStatusGrid.Rows.Count, "should filter transactions");

            importStatusGrid.Cell(0, 0).FindElement(By.TagName("a")).Click();

            driver.With<BatchSummaryPageObject>(page =>
            {
                driver.WaitForAngularWithTimeout();

                var url = driver.WithJs().GetUrl();

                Assert.True(url.Contains($"/#/bulkcaseimport/batchSummary/{batch}"), $"should display all transactions in the batch, but went to {url} instead.");

                Assert.AreEqual(batchFigures["total"], page.BulkImportSummaryGrid.Rows.Count);

                var caseRefLink = page.GetCaseRefLink(0, 3);

                var expectedUrl = "default.aspx?caseref=" + Uri.EscapeDataString(caseRefLink.Text);

                caseRefLink.TestIeOnlyUrl(expectedUrl);

                var bulkStatusFilter = new MultiSelectGridFilter(driver, "bulkImportSummary", "status");
                bulkStatusFilter.Open();
                Assert.AreEqual(4, bulkStatusFilter.ItemCount);
                bulkStatusFilter.SelectOption("Unmapped codes");
                bulkStatusFilter.SelectOption("Operator Review");
                bulkStatusFilter.Filter();
                Assert.AreEqual(batchFigures["mapping-issues"] + batchFigures["rejected"], page.BulkImportSummaryGrid.Rows.Count, "Should correctly filter all rows");

                driver.Navigate().Back();
            });

            Assert.AreEqual(batchFigures["amended"].ToString(), importStatusGrid.Cell(0, 2).Text, $"should contain {batchFigures["amended"]} transactions in amended");

            importStatusGrid.Cell(0, 2).FindElement(By.TagName("a")).Click();

            driver.With<BatchSummaryPageObject>(page =>
            {
                driver.WaitForAngularWithTimeout();

                var url = driver.WithJs().GetUrl();

                Assert.True(url.Contains($"/#/bulkcaseimport/batchSummary/{batch}/amendedCases"), $"should display all amended transactions in the batch, but went to {url} instead.");

                Assert.AreEqual(batchFigures["amended"], page.BulkImportSummaryGrid.Rows.Count, $"should display {batchFigures["amended"]} transactions in batch summary page for amended");

                driver.Navigate().Back();
            });

            Assert.AreEqual(batchFigures["unchanged"].ToString(), importStatusGrid.Cell(0, 3).Text, $"should contain {batchFigures["amended"]} transactions in amended");

            importStatusGrid.Cell(0, 3).FindElement(By.TagName("a")).Click();

            driver.With<BatchSummaryPageObject>(page =>
            {
                driver.WaitForAngularWithTimeout();

                var url = driver.WithJs().GetUrl();

                Assert.True(url.Contains($"/#/bulkcaseimport/batchSummary/{batch}/noChangeCases"), $"should display all unchanged transactions in the batch, but went to {url} instead.");

                Assert.AreEqual(batchFigures["unchanged"], page.BulkImportSummaryGrid.Rows.Count, $"should display {batchFigures["unchanged"]} transactions in batch summary page for unchanged cases");

                driver.Navigate().Back();
            });

            Assert.AreEqual(batchFigures["rejected"].ToString(), importStatusGrid.Cell(0, 4).Text, $"should contain {batchFigures["rejected"]} transactions in rejected");

            importStatusGrid.Cell(0, 4).FindElement(By.TagName("a")).Click();

            driver.With<BatchSummaryPageObject>(page =>
            {
                driver.WaitForAngularWithTimeout();

                var url = driver.WithJs().GetUrl();

                Assert.True(url.Contains($"/#/bulkcaseimport/batchSummary/{batch}/rejectedCases"), $"should display all rejected transactions in the batch, but went to {url} instead.");

                Assert.AreEqual(batchFigures["rejected"], page.BulkImportSummaryGrid.Rows.Count, $"should display {batchFigures["rejected"]} transactions in batch summary page for rejected");

                driver.Navigate().Back();
            });

            Assert.AreEqual(batchFigures["incomplete"].ToString(), importStatusGrid.Cell(0, 7).Text, $"should contain {batchFigures["incomplete"]} transactions in incomplete");

            importStatusGrid.Cell(0, 7).FindElement(By.TagName("a")).WithJs().Click();

            driver.With<BatchSummaryPageObject>(page =>
            {
                driver.WaitForAngularWithTimeout();

                var url = driver.WithJs().GetUrl();

                Assert.True(url.Contains($"/#/bulkcaseimport/batchSummary/{batch}/incomplete"), $"should display all incomplete transactions in the batch, but went to {url} instead.");

                Assert.AreEqual(batchFigures["incomplete"], page.BulkImportSummaryGrid.Rows.Count, $"should display {batchFigures["incomplete"]} transactions in batch summary page for incomplete");

                driver.Navigate().Back();
            });

            Assert.AreEqual(batchFigures["mapping-issues"].ToString(), importStatusGrid.Cell(0, 5).Text, $"should contain {batchFigures["mapping-issues"]} transactions in mapping-issues");

            importStatusGrid.Cell(0, 5).FindElement(By.TagName("a")).Click();

            driver.With<BatchSummaryPageObject>(page =>
            {
                driver.WaitForAngularWithTimeout();

                var url = driver.WithJs().GetUrl();

                Assert.True(url.Contains($"/#/bulkcaseimport/issues/mapping/{batch}"), $"should display transactions with mapping issues in the batch, but went to {url} instead.");

                driver.Navigate().Back();
            });

            Assert.AreEqual(batchFigures["name-issues"].ToString(), importStatusGrid.Cell(0, 6).Text, $"should contain {batchFigures["name-issues"]} transactions in name-issues");

            importStatusGrid.Cell(0, 6).FindElement(By.TagName("a")).Click();

            driver.With<BatchSummaryPageObject>(page =>
            {
                driver.WaitForAngularWithTimeout();

                var url = driver.WithJs().GetUrl();

                Assert.True(url.Contains($"/#/bulkcaseimport/issues/name/{batch}"), $"should display transactions with name issues in the batch, but went to {url} instead.");

                driver.Navigate().Back();
            });

            driver.With<ImportStatusPageObject>(page =>
            {
                page.ErrorLinkFor(batch).ClickWithTimeout();

                Assert.IsNotEmpty(page.Issues, "should display errors in the error popup");
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void ReverseImportedBatch(BrowserType browserType)
        {
            const int firstRow = 0;

            const int displayStatusColumnIndex = 2;

            const int batchIdentifierColumnIndex = 3;

            var driver = BrowserProvider.Get(browserType);

            var user = new Users()
                       .WithPermission(ApplicationTask.BulkCaseImport)
                       .WithPermission(ApplicationTask.ReverseImportedCases)
                       .Create();

            var db = new ReverseBatchDbSetup();

            _loggingSetOn = db.TurnOnLoggingForCases();

            var batch = db.CreateBatch(user.Id);

            SignIn(driver, "/#/bulkcaseimport", user.Username, user.Password);

            driver.With<ImportStatusPageObject>((page, popup) =>
            {
                var beforeStatus = page.ImportStatus.CellText(firstRow, displayStatusColumnIndex);

                page.ImportStatus.SelectIpCheckbox(firstRow, true);

                page.BulkMenu();

                page.ReverseButton.WithJs().Click();

                popup.ConfirmModal.Yes().WithJs().Click();

                driver.WaitForAngular();

                var afterStatus = page.ImportStatus.LockedCellText(firstRow, displayStatusColumnIndex);

                Assert.AreNotEqual(beforeStatus, afterStatus, "Status should have been changed.");

                Assert.AreEqual("Submitted for Reversal", afterStatus, "Status should be 'Submitted for Reversal'.");
            });

            bool IsBatchBeingReversed()
            {
                return DbSetup.Do(x => x.DbContext.Set<ProcessRequest>().Any(_ => _.BatchId == batch.BatchId));
            }

            var dateTime = DateTime.Now;

            do
            {
                WaitHelper.Wait(1000);
                if (!IsBatchBeingReversed())
                    break;

            }
            while (DateTime.Now - dateTime < TimeSpan.FromMinutes(2));

            ReloadPage(driver);

            driver.With<ImportStatusPageObject>((page, popup) =>
            {
                var reversedStatus = page.ImportStatus.LockedCellText(firstRow, displayStatusColumnIndex);

                Assert.AreEqual("Output Produced or Reversed", reversedStatus, "Should set Status to 'Output Produced or Reversed'.");

                Assert.AreEqual($"{batch.BatchName}_REV", page.ImportStatus.LockedCellText(firstRow, batchIdentifierColumnIndex), $"Should set {batch.BatchName} to {batch.BatchName}_REV");
            });

            Assert.AreEqual(0, DbSetup.Do(x => x.DbContext.Set<EdeTransactionBody>()
                                                .Include(_ => _.CaseDetails)
                                                .Where(_ => _.BatchId == batch.BatchId && _.CaseDetails.CaseId != null)
                                                .Select(_ => _.CaseDetails)
                                                .Count()), "Should no longer have any ede case details for the batch");

            var casesPreviousImported = batch.CaseIds;

            var casesRemained = DbSetup.Do(x => x.DbContext.Set<Case>().Count(@case => casesPreviousImported.Contains(@case.Id)));

            Assert.AreEqual(0, casesRemained, "Should delete all cases imported in the batch being reversed.");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ResubmitImportBatch(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            var user = new Users().WithPermission(ApplicationTask.BulkCaseImport).Create();

            var batchData = new ViewBatchSummaryDbSetup().CreateBatch();

            var batchId = batchData.Item1;

            var initialCount = DbSetup.Do(x => x.DbContext.Set<TransactionInfo>().Count(_ => _.BatchId == batchId));

            var result = initialCount;

            SignIn(driver, "/#/bulkcaseimport", user.Username, user.Password);

            var importStatusPage = new ImportStatusPageObject(driver);

            importStatusPage.ResumitBatch(batchData.Item1);

            new CommonPopups(driver).WaitForFlashAlert();

            int DataPollerFunc()
            {
                return DbSetup.Do(x => x.DbContext.Set<TransactionInfo>().Count(_ => _.BatchId == batchId));
            }

            var dateTime = DateTime.Now;
            do
            {
                if (result != initialCount)
                {
                    break;
                }

                WaitHelper.Wait(1000);
                result = DataPollerFunc();
            }
            while (DateTime.Now - dateTime < TimeSpan.FromMinutes(2));

            Assert.Greater(result, initialCount, "Should run ede_MapData which increments a transaction info count for the batch being processed - i.e. the batch is being processed.");

            Assert.Null(importStatusPage.ResubmitLinkFor(batchId), "should no longer be possible to resubmit");
        }
    }
}