using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Picklists.FilePart;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.DataValidation;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.FileLocations
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedFileLocationsComponent : IntegrationTest
    {
        List<DataValidation> DataValidations { get; set; }

        [TearDown]
        public void TearDown()
        {
            var setup = new CaseDetailsActionsDbSetup();
            setup.ResetDataValidations(DataValidations);
        }

        public void TurnOffDataValidations()
        {
            DbSetup.Do((db) =>
            {
                DataValidations = db.DbContext.Set<DataValidation>().Where(_ => _.InUseFlag).ToList();
                foreach (var dataValidation in DataValidations)
                {
                    dataValidation.InUseFlag = false;
                }
                db.DbContext.SaveChanges();
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedFileLocationsComponentLifecycle(BrowserType browserType)
        {
            TurnOffDataValidations();

            var setup = new CaseDetailsDbSetup();
            var casesData = setup.NavigationDataSetup();
            var @case = (Case)casesData.Case1;
            setup.GetScreenCriteriaBuilder(@case)
                  .WithTopicControl(KnownCaseScreenTopics.CaseHeader)
                  .WithTopicControl(KnownCaseScreenTopics.FileLocations);
            setup.SetupCaseFileLocations(@case);

            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainFileTracking, Allow.Execute | Allow.Modify | Allow.Create | Allow.Delete)
                       .Create();
            SignIn(driver, "/#/deve2e/hosted-test", user.Username, user.Password);
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case View File Location";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(@case.Irn);
            driver.WaitForAngular();

            page.ProgramPicklist.SelectItem(KnownCasePrograms.CaseEntry);
            driver.WaitForAngular();

            page.CaseSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");
            var hostedFileLocationsTopic = new CaseFileLocationsTopic(driver);
            var caseFileLocationsHistory = new CaseFileLocationsHistory(driver);

            driver.DoWithinFrame(() =>
            {
                Assert.AreEqual(2, hostedFileLocationsTopic.FileLocationsGrid.Rows.Count, "Hosted File Locations grid contains 2 records");
                driver.WaitForAngular();

                var pageObject = new HostedTopicPageObject(driver);
                Assert.True(pageObject.SaveButton.IsDisabled());
                Assert.True(pageObject.RevertButton.IsDisabled());

                hostedFileLocationsTopic.FileLocationsGrid.ClickDelete(0);

                Assert.AreEqual(true, hostedFileLocationsTopic.FileLocationsGrid.IsRowDeleteMode(0));
                Assert.False(pageObject.SaveButton.IsDisabled());
                Assert.False(pageObject.RevertButton.IsDisabled());

                hostedFileLocationsTopic.Revert();

                Assert.AreEqual(false, hostedFileLocationsTopic.FileLocationsGrid.IsRowDeleteMode(0));
                Assert.True(pageObject.SaveButton.IsDisabled());
                Assert.True(pageObject.RevertButton.IsDisabled());

                hostedFileLocationsTopic.FileLocationsGrid.AddButton.ClickWithTimeout();

                #region File Location History for file part
                Assert.True(caseFileLocationsHistory.HistoryIconButton.Displayed);
                caseFileLocationsHistory.HistoryIconButton.ClickWithTimeout();
                driver.WaitForAngular();
                Assert.True(caseFileLocationsHistory.HistoryModalTitle.Displayed);
                Assert.AreEqual(1, caseFileLocationsHistory.LastLocationGrid.Rows.Count, "File Location History for file part: should show 1 row");
                caseFileLocationsHistory.HistoryModal.ClickWithTimeout();
                #endregion

                Assert.NotNull(hostedFileLocationsTopic.Modal);
                Assert.AreEqual(false, hostedFileLocationsTopic.ModalApply.Enabled);
                Assert.AreEqual(true, hostedFileLocationsTopic.ModalCancel.Enabled);
                Assert.AreEqual(false, hostedFileLocationsTopic.AddAnotherCheckbox.IsChecked);

                hostedFileLocationsTopic.FileLocationPicklist.Typeahead.WithJs().Focus();
                hostedFileLocationsTopic.FileLocationPicklist.Clear();
                hostedFileLocationsTopic.FileLocationPicklist.Typeahead.SendKeys("123");
                Assert.True(hostedFileLocationsTopic.FileLocationPicklist.HasError);
                Assert.AreEqual(false, hostedFileLocationsTopic.ModalApply.Enabled);
                hostedFileLocationsTopic.FileLocationPicklist.Clear();
                Assert.True(hostedFileLocationsTopic.FileLocationPicklist.HasError);
                Assert.AreEqual(false, hostedFileLocationsTopic.ModalApply.Enabled);

                hostedFileLocationsTopic.FileLocationPicklist.Typeahead.WithJs().Focus();
                hostedFileLocationsTopic.FileLocationPicklist.Clear();
                hostedFileLocationsTopic.FileLocationPicklist.Typeahead.SendKeys("Fil");
                hostedFileLocationsTopic.IssuedByPicklist.Typeahead.WithJs().Focus();
                Assert.AreEqual(true, hostedFileLocationsTopic.ModalApply.Enabled);

                hostedFileLocationsTopic.AddAnotherCheckbox.Click();
                hostedFileLocationsTopic.ModalApply.ClickWithTimeout();
                Assert.NotNull(hostedFileLocationsTopic.Modal);
                hostedFileLocationsTopic.AddAnotherCheckbox.Click();

                hostedFileLocationsTopic.FileLocationPicklist.Typeahead.WithJs().Focus();
                hostedFileLocationsTopic.FileLocationPicklist.Clear();
                hostedFileLocationsTopic.FileLocationPicklist.Typeahead.SendKeys("Fil");
                hostedFileLocationsTopic.IssuedByPicklist.Typeahead.WithJs().Focus();

                hostedFileLocationsTopic.ModalApply.ClickWithTimeout();
                driver.WaitForAngular();

                Assert.NotNull(hostedFileLocationsTopic.Modal);
                Assert.True(hostedFileLocationsTopic.ValidationOkButton.Enabled);
                hostedFileLocationsTopic.ValidationOkButton.Click();
                hostedFileLocationsTopic.FileLocationPicklist.Typeahead.WithJs().Focus();
                hostedFileLocationsTopic.FileLocationPicklist.Clear();
                hostedFileLocationsTopic.FileLocationPicklist.Typeahead.SendKeys("Records");
                hostedFileLocationsTopic.FileLocationPicklist.Blur();
                Assert.AreEqual(true, hostedFileLocationsTopic.AddPicklistButton.Enabled);

                hostedFileLocationsTopic.FileLocationsGrid.AddButton.ClickWithTimeout();
                var saveSearch = new FilePartPicklistDetailPage(driver);
                hostedFileLocationsTopic.FilePartPicklist.OpenPickList(string.Empty);
                hostedFileLocationsTopic.FilePartPicklist.FindElement(By.XPath("//span[@class='cpa cpa-icon-plus-circle']")).ClickWithTimeout();
                Assert.AreEqual(true, hostedFileLocationsTopic.AddPicklistButton.Enabled);
                saveSearch.DescriptionTextArea().SendKeys("Part 1");
                hostedFileLocationsTopic.FilePartPicklist.Apply();
                hostedFileLocationsTopic.FilePartPicklist.FindElement(By.XPath("//span[@class='cpa cpa-icon-plus-circle']")).ClickWithTimeout();
                saveSearch.DescriptionTextArea().SendKeys("Part 2");
                hostedFileLocationsTopic.FilePartPicklist.Apply();
                hostedFileLocationsTopic.FilePartPicklist.FindElement(By.XPath("//span[@class='cpa cpa-icon-plus-circle']")).ClickWithTimeout();
                saveSearch.DescriptionTextArea().SendKeys("e2e-add");
                hostedFileLocationsTopic.FilePartPicklist.Apply();

                hostedFileLocationsTopic.FilePartPicklist.SearchFor("e2e-add");
                Assert.AreEqual("e2e-add", hostedFileLocationsTopic.FilePartPicklist.SearchGrid.CellText(0, 0), "Should show added description");
                hostedFileLocationsTopic.FilePartPicklist.EditRow(0);
                saveSearch.DescriptionTextArea().Clear();
                saveSearch.DescriptionTextArea().SendKeys("e2e-edit");
                hostedFileLocationsTopic.FilePartPicklist.Apply();
                hostedFileLocationsTopic.CloseButton.WithJs().Click();

                hostedFileLocationsTopic.FilePartPicklist.SearchFor("e2e-edit");
                Assert.AreEqual("e2e-edit", hostedFileLocationsTopic.FilePartPicklist.SearchGrid.CellText(0, 0), "Should show added description");
                hostedFileLocationsTopic.FilePartPicklist.DeleteRow(0);
                var popups = new CommonPopups(driver);
                popups.ConfirmNgDeleteModal.Delete.WithJs().Click();

                hostedFileLocationsTopic.FilePartPicklist.Close();
                hostedFileLocationsTopic.FilePartPicklist.Typeahead.WithJs().Focus();
                hostedFileLocationsTopic.FilePartPicklist.Clear();
                hostedFileLocationsTopic.FilePartPicklist.Typeahead.SendKeys("Part 1");

                hostedFileLocationsTopic.FileLocationPicklist.Typeahead.Clear();
                hostedFileLocationsTopic.FileLocationPicklist.Clear();
                hostedFileLocationsTopic.FileLocationPicklist.Typeahead.WithJs().Focus();
                hostedFileLocationsTopic.FileLocationPicklist.Clear();
                hostedFileLocationsTopic.FileLocationPicklist.Typeahead.SendKeys("Fil");

                hostedFileLocationsTopic.IssuedByPicklist.Typeahead.WithJs().Focus();
                hostedFileLocationsTopic.IssuedByPicklist.Clear();
                hostedFileLocationsTopic.IssuedByPicklist.Typeahead.SendKeys("BO");

                hostedFileLocationsTopic.WhenMovedDate.Input.WithJs().Focus();
                hostedFileLocationsTopic.WhenMovedDate.Input.WithJs().Click();
                Assert.True(hostedFileLocationsTopic.WhenMovedDate.Input.Enabled);

                Assert.AreEqual(true, hostedFileLocationsTopic.ModalApply.Enabled);

                hostedFileLocationsTopic.AddAnotherCheckbox.Click();
                hostedFileLocationsTopic.ModalApply.ClickWithTimeout();
                Assert.NotNull(hostedFileLocationsTopic.Modal);
                hostedFileLocationsTopic.AddAnotherCheckbox.Click();

                hostedFileLocationsTopic.FilePartPicklist.Typeahead.WithJs().Focus();
                hostedFileLocationsTopic.FilePartPicklist.Clear();
                hostedFileLocationsTopic.FilePartPicklist.Typeahead.SendKeys("Part 2");

                hostedFileLocationsTopic.FileLocationPicklist.Typeahead.WithJs().Focus();
                hostedFileLocationsTopic.FileLocationPicklist.Clear();
                hostedFileLocationsTopic.FileLocationPicklist.Typeahead.SendKeys("Fil");
                hostedFileLocationsTopic.FileLocationPicklist.Blur();

                Assert.AreEqual(true, hostedFileLocationsTopic.ModalApply.Enabled);
                hostedFileLocationsTopic.ModalApply.ClickWithTimeout();
                driver.WaitForAngular();

                hostedFileLocationsTopic.FileLocationsGrid.ClickEdit(0);
                hostedFileLocationsTopic.FileLocationPicklist.Typeahead.WithJs().Focus();
                hostedFileLocationsTopic.FileLocationPicklist.Clear();
                hostedFileLocationsTopic.FileLocationPicklist.Typeahead.SendKeys("Des");
                hostedFileLocationsTopic.FileLocationPicklist.Blur();
                Assert.AreEqual(true, hostedFileLocationsTopic.ModalApply.Enabled);
                hostedFileLocationsTopic.ModalApply.ClickWithTimeout();

                driver.WaitForAngular();
                pageObject.SaveButton.Click();
            });

            page.CallOnRequestDataResponse(new HostedTestPageObject.DataReceivedMessage<bool>("isPoliceImmediately", false));

            driver.DoWithinFrame(() =>
            {
                var pageObject = new HostedTopicPageObject(driver);
                Assert.True(pageObject.SaveButton.IsDisabled(), "Saved Successfully if sanity check only warnings");
                Assert.True(pageObject.RevertButton.IsDisabled(), "Saved Successfully if sanity check only warnings");
            });
        }
    }
}
