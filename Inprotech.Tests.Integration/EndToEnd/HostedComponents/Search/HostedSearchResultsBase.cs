using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Search;
using Inprotech.Tests.Integration.EndToEnd.Search.Case;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Queries;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.Search
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedSearchResultsBase : IntegrationTest
    {
        protected static dynamic AddColumnForDefaultPresentation(int contextId, string columnLabel)
        {
            return DbSetup.Do(setup =>
            {
                var globalDefaultPresentation = setup.DbContext.Set<QueryPresentation>().Single(_ => _.ContextId == contextId && _.IsDefault && _.PresentationType == null);
                var presentationId = globalDefaultPresentation.Id;

                var qcc = setup.DbContext.Set<QueryContextColumn>().Single(_ => _.ContextId == contextId && _.QueryColumn.ColumnLabel.Equals(columnLabel));
                var columnId = qcc.ColumnId;

                var maxSequence = setup.DbContext.Set<QueryContent>().Where(_ => _.PresentationId == presentationId && _.ContextId == contextId).Max(_ => _.DisplaySequence);

                setup.DbContext.Set<QueryContent>().Add(new QueryContent
                {
                    PresentationId = presentationId,
                    ColumnId = columnId,
                    ContextId = contextId,
                    DisplaySequence = maxSequence
                });
                setup.DbContext.SaveChanges();

                return new
                {
                    ColumnSequence = maxSequence
                };
            });
        }

        protected static bool GetRFIDSiteControlValue()
        {
            return DbSetup.Do(setup =>
            {
                var rfidSiteControl = setup.DbContext.Set<SiteControl>().FirstOrDefault(sc => sc.ControlId == "RFID System");
                return rfidSiteControl.BooleanValue.HasValue && rfidSiteControl.BooleanValue.Value;
            });
        }

        protected static void SetRFIDSiteControl(bool siteControlValue)
        {
            DbSetup.Do(setup =>
            {
                var rfidSiteControl = setup.DbContext.Set<SiteControl>().FirstOrDefault(sc => sc.ControlId == "RFID System");
                rfidSiteControl.BooleanValue = siteControlValue;
                setup.DbContext.SaveChanges();
            });
        }

        protected void TestHostedSearchResultsLifeCycle(NgWebDriver driver, int queryContextKey, string user = "internal", int? queryKey = null)
        {
            SignIn(driver, $"/#/deve2e/hosted-test", user, user);
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Search Results";
            driver.WaitForAngular();
            page.WaitForLifeCycleAction("onInit");
            page.CallOnInit(new PostMessage() { QueryContextKey = queryContextKey, QueryKey = queryKey });
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() => Assert.Throws<NoSuchElementException>(() => page.HostedSearchPage.CloseButton(), "Close Button Is not displayed"));
            var originalSrc = page.FrameSource;
            AssertPresentationButtonSendsLifecycleMessage(driver, page, originalSrc);
        }

        protected static void AssertBulkActionMenuDoesNotHaveOpenWithProgram(NgWebDriver driver)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.ActionMenu.OpenOrClose();
                Assert.IsNull(grid.ActionMenu.Option("open-with-program"));
            });
        }

        protected static void AssertBulkActionMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation, string programName)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.ActionMenu.OpenOrClose();
                Assert.IsTrue(grid.ActionMenu.Option("open-with-program").Disabled());
                grid.SelectRow(1);
                grid.ActionMenu.OpenOrClose();
                Assert.IsFalse(grid.ActionMenu.Option("open-with-program").Disabled());
                driver.Hover(grid.ActionMenu.Option("open-with-program").FindElement(By.ClassName("cpa-icon-right")));
                driver.WaitForAngularWithTimeout();
                grid.ActionMenu.Option(programName).WithJs().Click();
            });

            Assert.AreEqual(3, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open case details");
            Assert.AreEqual(programName, page.NavigationMessages.Last().Args[3], "Posts Message to open case details");
        }

        protected static void AssertProgramsTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation, string programName)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(1);
                page.HostedSearchPage.OpenWithProgramMenu.Click();
                driver.FindElement(By.CssSelector("div#" + programName + " span:nth-child(2)")).WithJs().Click();
            });

            Assert.AreEqual(3, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertClickingIrnSendsNavigationMessage(NgWebDriver driver, string navigationLocation, int expectedNavigationMessageArgsCount)
        {
            var page = new HostedTestPageObject(driver);
            var originalSrc = page.FrameSource;
            Assert.AreEqual(0, page.NavigationMessages.Count, "No Navigation Messages Received");
            driver.DoWithinFrame(() => page.HostedSearchPage.ResultGrid.Rows.First().FindElements(By.TagName("a"))?.First().ClickWithTimeout());
            Assert.AreEqual(originalSrc, page.FrameSource, "IFrame has not changed URL");
            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open details");

            driver.DoWithinFrame(() => page.HostedSearchPage.ResultGrid.Rows.Skip(1).First().FindElements(By.TagName("a"))?.First().ClickWithTimeout());
            Assert.AreEqual(originalSrc, page.FrameSource, "IFrame has not changed URL");
            Assert.AreEqual(2, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open details");
            Assert.AreEqual(expectedNavigationMessageArgsCount, page.NavigationMessages.Last().Args.Length, "Posts Message to open case details");
        }

        static void AssertPresentationButtonSendsLifecycleMessage(NgWebDriver driver, HostedTestPageObject page, string originalSrc)
        {
            driver.DoWithinFrame(() => page.HostedSearchResultsPage.PresentationButton.WithJs().Click());
            Assert.AreEqual(originalSrc, page.FrameSource, "IFrame has not changed URL");
            Assert.AreEqual("searchResultHost", page.LifeCycleMessages.Last().Target, "Posts Message to open search presentation");
            Assert.AreEqual("onSearchPresentationModal", page.LifeCycleMessages.Last().Action, "Posts Message to open search presentation");
        }

        protected static void AssertGlobalNameChangeMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                var gncMenu = grid.ActionMenu.Option("global-name-change");
                grid.ActionMenu.OpenOrClose();
                Assert.IsTrue(gncMenu.Disabled());
                grid.SelectRow(1);
                grid.ActionMenu.OpenOrClose();
                Assert.IsFalse(gncMenu.Disabled());
                gncMenu.WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertRecordTimeTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.RecordTimeMenu.WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertOpenRemindersTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.TaskMenuFor(CaseTaskMenuItemOperationType.OpenReminders).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertCreateAdHocDateTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.TaskMenuFor(CaseTaskMenuItemOperationType.CreateAdHocDate).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertRequestCaseFileTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.TaskMenuFor(CaseTaskMenuItemOperationType.RequestCaseFile).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertFirstToFileTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.TaskMenuFor(CaseTaskMenuItemOperationType.OpenFirstToFile).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertRecordWipTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.TaskMenuFor(CaseTaskMenuItemOperationType.RecordWip).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertCopyCaseTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.TaskMenuFor(CaseTaskMenuItemOperationType.CopyCase).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertMaintainCaseDetailsTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.EditCaseMenu.Click();
                page.HostedSearchPage.TaskMenuFor(CaseTaskMenuItemOperationType.MaintainCase).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertDocketingWizardTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.EditCaseMenu.Click();
                page.HostedSearchPage.TaskMenuFor(CaseTaskMenuItemOperationType.DocketingWizard).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertWorkflowWizardTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.EditCaseMenu.Click();
                page.HostedSearchPage.TaskMenuFor(CaseTaskMenuItemOperationType.WorkflowWizard).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertMaintainFileLocationTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.EditCaseMenu.Click();
                page.HostedSearchPage.TaskMenuFor(CaseTaskMenuItemOperationType.MaintainFileLocation).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertClickingCurrencyHyperlinkColumnSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);
            var originalSrc = page.FrameSource;
            driver.DoWithinFrame(() =>
            {
                var listOfElements = driver.FindElements(By.XPath("//ipx-currency[1]/a"));
                listOfElements.First().ClickWithTimeout();
            });
            Assert.AreEqual(originalSrc, page.FrameSource, "IFrame has not changed URL");
            Assert.AreEqual(4, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open details");
        }

        protected static void AssertClickingNameSummaryHyperlinkColumnSendsNavigationMessage(NgWebDriver driver, string navigationLocation, short columnSequence)
        {
            var page = new HostedTestPageObject(driver);
            var sequence = columnSequence + 2;
            var originalSrc = page.FrameSource;
            driver.DoWithinFrame(() =>
            {
                driver.FindElement(By.XPath("//tr[1]//td[" + sequence + "]//div[1]//ipx-hosted-url[1]//a[1]")).ClickWithTimeout();
            });
            Assert.AreEqual(originalSrc, page.FrameSource, "IFrame has not changed URL");
            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open details");
        }

        protected static void AssertClickingTotalWipHyperlinkColumnSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);
            var originalSrc = page.FrameSource;
            driver.DoWithinFrame(() =>
            {
                var listOfElements = driver.FindElements(By.XPath("//ipx-currency[1]/a"));
                listOfElements.First().ClickWithTimeout();
            });
            Assert.AreEqual(originalSrc, page.FrameSource, "IFrame has not changed URL");
            Assert.AreEqual(3, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open details");
        }

        protected static void AssertMaintainNameTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.EditNameMenu.Click();
                page.HostedSearchPage.TaskMenuFor(NameTaskMenuItemOperationType.MaintainName).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertMaintainNameTextTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.EditNameMenu.Click();
                page.HostedSearchPage.TaskMenuFor(NameTaskMenuItemOperationType.MaintainNameText).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertMaintainNameAttributesTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.EditNameMenu.Click();
                page.HostedSearchPage.TaskMenuFor(NameTaskMenuItemOperationType.MaintainNameAttributes).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertMaintainPriorArtTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.TaskMenuFor(PriorArtTaskMenuItemOperationType.MaintainPriorArt).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertAdHocDateForNameTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                page.HostedSearchPage.TaskMenuFor(NameTaskMenuItemOperationType.AdHocDateForName).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertCreateContactActivityTaskMenuSendsNavigationMessage(NgWebDriver driver, string navigationLocation)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                grid.OpenContexualTaskMenu(0);
                driver.FindElement(By.CssSelector($"div#NewActivityWizardForName span:nth-child(2)")).WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual(navigationLocation, page.NavigationMessages.Last().Args[0], "Posts Message to open global name change");
        }

        protected static void AssertCreateBillMenuSendsNavigationMessage(NgWebDriver driver, string optionMenu, string title)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                var gncMenu = grid.ActionMenu.Option(optionMenu);
                grid.ActionMenu.OpenOrClose();
                Assert.IsTrue(gncMenu.Disabled());
                grid.ActionMenu.SelectAll();
                Assert.IsFalse(gncMenu.Disabled());
                grid.ActionMenu.SelectAll();
                Assert.IsTrue(gncMenu.Disabled());
                grid.SelectRow(1);
                grid.ActionMenu.OpenOrClose();
                Assert.IsFalse(gncMenu.Disabled());
                gncMenu.WithJs().Click();
            });

            Assert.AreEqual(1, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
            Assert.AreEqual("CreateBills", page.NavigationMessages.Last().Args[0], "Posts Message to Create Bills");
            Assert.AreEqual(title, page.NavigationMessages.Last().Args[2], "Posts Title Message to Create Bills");
        }

        protected void AssertSelectedRecordInPreviewPane(NgWebDriver driver, int queryContextKey, string user = "internal", int? queryKey = null)
        {
            SignIn(driver, $"/#/deve2e/hosted-test", user, user);
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Search Results";
            driver.WaitForAngular();
            page.WaitForLifeCycleAction("onInit");
            page.CallOnInit(new PostMessage() { QueryContextKey = queryContextKey, QueryKey = queryKey });
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() => Assert.Throws<NoSuchElementException>(() => page.HostedSearchPage.CloseButton(), "Close Button Is not displayed"));
            var originalSrc = page.FrameSource;
            AssertPresentationButtonSendsLifecycleMessage(driver, page, originalSrc);
        }

        protected static void AssertSelectedRecordInPreviewPane(NgWebDriver driver, string navigationLocation, int expectedNavigationMessageArgsCount)
        {
            var page = new HostedTestPageObject(driver);
            driver.DoWithinFrame(() =>
            {
                Assert.IsFalse(driver.FindElements(By.Id("namePreviewPane")).Any());
                page.HostedSearchPage.TogglePreviewSwitch.ClickWithTimeout();
                Assert.IsTrue(driver.FindElement(By.Id("namePreviewPane")).WithJs().IsVisible());
                page.HostedSearchPage.ResultGrid.ClickRow(0);
                Assert.IsTrue(driver.FindElements(By.Id("remarks")).Any());
                Assert.IsTrue(driver.FindElements(By.Id("category")).Any());
            });
        }

        protected static void AssertSelectedRecordExport(NgWebDriver driver)
        {
            var page = new HostedTestPageObject(driver);

            driver.DoWithinFrame(() =>
            {
                var grid = page.HostedSearchPage.ResultGrid;
                var exportPdfMenu = grid.ActionMenu.Option("export-pdf");
                var selectAllMenu = page.HostedSearchPage.SelectAllMenu();
                grid.ActionMenu.OpenOrClose();
                Assert.AreEqual("Export all to PDF", exportPdfMenu.Text);
                Assert.AreEqual("Select all", selectAllMenu.Text);
                selectAllMenu.WithJs().Click();
                grid.SelectRow(1);
                grid.ActionMenu.OpenOrClose();
                Assert.AreEqual("Export selected to PDF", exportPdfMenu.Text);
                Assert.AreEqual("Deselect all", selectAllMenu.Text);
                exportPdfMenu.WithJs().Click();
                driver.WaitForAngularWithTimeout();
                Assert.AreEqual("Your export request to PDF has been submitted successfully.", page.HostedSearchPage.MessageDiv.Text);
            });

            Assert.AreEqual(0, page.NavigationMessages.Count, "Received Navigation Message To Be Handled By Parent Page");
        }
    }
}
