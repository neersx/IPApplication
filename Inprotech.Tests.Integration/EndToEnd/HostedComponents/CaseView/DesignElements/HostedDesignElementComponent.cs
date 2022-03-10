using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.DataValidation;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.DesignElements
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedDesignElementComponent : IntegrationTest
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
        public void TestHostedDesignElementComponentLifecycle(BrowserType browserType)
        {
            TurnOffDataValidations();

            var setup = new CaseDetailsDbSetup();
            var casesData = setup.NavigationDataSetup();
            var @case = (Case)casesData.Case1;
            setup.GetScreenCriteriaBuilder(@case)
                  .WithTopicControl(KnownCaseScreenTopics.CaseHeader)
                  .WithTopicControl(KnownCaseScreenTopics.DesignElement);
            var designElements = setup.SetupDesignElementAndCaseImage(@case);

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test");
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case View Design Elements";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(@case.Irn);
            driver.WaitForAngular();

            page.ProgramPicklist.SelectItem(KnownCasePrograms.CaseEntry);
            driver.WaitForAngular();

            page.CaseSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var hostedDesignElementTopic = new CaseDesignElementsTopic(driver);
                Assert.AreEqual(2, hostedDesignElementTopic.DesignElementsGrid.Rows.Count, "Hosted Design Element grid contains 2 records");
                driver.WaitForAngular();

                var pageObject = new HostedTopicPageObject(driver);
                Assert.True(pageObject.SaveButton.IsDisabled());
                Assert.True(pageObject.RevertButton.IsDisabled());

                hostedDesignElementTopic.DesignElementsGrid.ClickDelete(0);

                Assert.AreEqual(true, hostedDesignElementTopic.DesignElementsGrid.IsRowDeleteMode(0));
                Assert.False(pageObject.SaveButton.IsDisabled());
                Assert.False(pageObject.RevertButton.IsDisabled());

                hostedDesignElementTopic.Revert();

                Assert.AreEqual(false, hostedDesignElementTopic.DesignElementsGrid.IsRowDeleteMode(0));
                Assert.True(pageObject.SaveButton.IsDisabled());
                Assert.True(pageObject.RevertButton.IsDisabled());

                hostedDesignElementTopic.DesignElementsGrid.ClickDelete(0);
                Assert.AreEqual(true, hostedDesignElementTopic.DesignElementsGrid.IsRowDeleteMode(0));
                Assert.False(pageObject.SaveButton.IsDisabled());
                Assert.False(pageObject.RevertButton.IsDisabled());

                hostedDesignElementTopic.DesignElementsGrid.ClickRevert(0);
                Assert.AreEqual(false, hostedDesignElementTopic.DesignElementsGrid.IsRowDeleteMode(0));
                Assert.True(pageObject.SaveButton.IsDisabled());
                Assert.True(pageObject.RevertButton.IsDisabled());

                hostedDesignElementTopic.DesignElementsGrid.AddButton.ClickWithTimeout();

                Assert.NotNull(hostedDesignElementTopic.Modal);
                Assert.AreEqual(false, hostedDesignElementTopic.ModalApply.Enabled);
                Assert.AreEqual(true, hostedDesignElementTopic.ModalCancel.Enabled);
                Assert.AreEqual(false, hostedDesignElementTopic.AddAnotherCheckbox.IsChecked);

                hostedDesignElementTopic.FirmElementCaseRef.Input.SendKeys(Fixture.String(20));
                hostedDesignElementTopic.FirmElementCaseRef.Input.Click();
                Assert.AreEqual(true, hostedDesignElementTopic.ModalApply.Enabled);

                hostedDesignElementTopic.FirmElementCaseRef.Input.Clear();
                Assert.True(hostedDesignElementTopic.FirmElementCaseRef.HasError);

                hostedDesignElementTopic.FirmElementCaseRef.Input.SendKeys(Fixture.String(21));
                hostedDesignElementTopic.ClientElementCaseRef.Input.SendKeys(Fixture.String(255));
                hostedDesignElementTopic.ClientElementCaseRef.Input.Click();
                Assert.True(hostedDesignElementTopic.FirmElementCaseRef.HasError);
                Assert.True(hostedDesignElementTopic.ClientElementCaseRef.HasError);
                Assert.AreEqual(false, hostedDesignElementTopic.ModalApply.Enabled);

                hostedDesignElementTopic.FirmElementCaseRef.Input.Clear();
                hostedDesignElementTopic.ClientElementCaseRef.Input.Clear();

                hostedDesignElementTopic.FirmElementCaseRef.Input.SendKeys("111-Firm");
                hostedDesignElementTopic.ClientElementCaseRef.Input.SendKeys(Fixture.String(5));
                hostedDesignElementTopic.ElementDescription.Input.SendKeys(Fixture.String(5));
                hostedDesignElementTopic.ElementOfficialNo.Input.SendKeys(Fixture.String(5));
                hostedDesignElementTopic.NoOfViews.Input.SendKeys(Fixture.String(2));
                Assert.True(hostedDesignElementTopic.NoOfViews.HasError);
                hostedDesignElementTopic.NoOfViews.Input.Clear();
                hostedDesignElementTopic.NoOfViews.Input.SendKeys(Fixture.Integer().ToString());
                hostedDesignElementTopic.RegistrationNo.Input.SendKeys(Fixture.String(5));
                hostedDesignElementTopic.RegistrationNo.Input.SendKeys(Fixture.String(5));
                hostedDesignElementTopic.ImagePicklist.Typeahead.WithJs().Focus();
                hostedDesignElementTopic.ImagePicklist.Typeahead.SendKeys("Big Dog");
                Assert.True(hostedDesignElementTopic.StopRenewDate.Input.Enabled);

                hostedDesignElementTopic.AddAnotherCheckbox.Click();
                hostedDesignElementTopic.ModalApply.ClickWithTimeout();
                Assert.NotNull(hostedDesignElementTopic.Modal);
                hostedDesignElementTopic.AddAnotherCheckbox.Click();

                hostedDesignElementTopic.FirmElementCaseRef.Input.SendKeys(designElements.designElement1.FirmElementId);
                hostedDesignElementTopic.FirmElementCaseRef.Input.Click();
                hostedDesignElementTopic.ModalApply.ClickWithTimeout();
                driver.WaitForAngular();
                Assert.NotNull(hostedDesignElementTopic.Modal);
                Assert.True(hostedDesignElementTopic.FirmElementCaseRef.HasError, "Duplicate firm element reference exists");

                hostedDesignElementTopic.FirmElementCaseRef.Input.Clear();
                hostedDesignElementTopic.FirmElementCaseRef.Input.SendKeys(Fixture.String(5));
                hostedDesignElementTopic.FirmElementCaseRef.Input.Click();
                hostedDesignElementTopic.ImagePicklist.Typeahead.WithJs().Focus();
                hostedDesignElementTopic.ImagePicklist.Typeahead.SendKeys(designElements.imageDetail.ImageDescription);
                hostedDesignElementTopic.FirmElementCaseRef.Input.Click();
                hostedDesignElementTopic.ModalApply.ClickWithTimeout();
                driver.WaitForAngular();
                Assert.True(hostedDesignElementTopic.ImagePicklist.HasError, "Duplicate image exists");
                Assert.NotNull(driver.FindElement(By.CssSelector(".tags-error")));

                hostedDesignElementTopic.FirmElementCaseRef.Input.Clear();
                hostedDesignElementTopic.ImagePicklist.Clear();
                hostedDesignElementTopic.FirmElementCaseRef.Input.SendKeys("112-Firm");
                hostedDesignElementTopic.ClientElementCaseRef.Input.SendKeys(Fixture.String(5));
                hostedDesignElementTopic.ElementDescription.Input.SendKeys(Fixture.String(5));
                hostedDesignElementTopic.ElementOfficialNo.Input.SendKeys(Fixture.String(5));
                hostedDesignElementTopic.NoOfViews.Input.SendKeys(Fixture.Integer().ToString());
                hostedDesignElementTopic.ModalApply.ClickWithTimeout();

                Assert.AreEqual(4, hostedDesignElementTopic.DesignElementsGrid.Rows.Count, "Hosted Design Element grid contains 4 records");
                Assert.AreEqual("111-Firm", hostedDesignElementTopic.DesignElementsGrid.CellText(2, 2));
                Assert.AreEqual("112-Firm", hostedDesignElementTopic.DesignElementsGrid.CellText(3, 2));

                hostedDesignElementTopic.DesignElementsGrid.ClickEdit(0);
                hostedDesignElementTopic.FirmElementCaseRef.Input.Clear();
                hostedDesignElementTopic.FirmElementCaseRef.Input.SendKeys(designElements.designElement1.FirmElementId);
                hostedDesignElementTopic.ClientElementCaseRef.Input.Clear();
                hostedDesignElementTopic.ClientElementCaseRef.Input.SendKeys(designElements.designElement1.ClientElementId + "-updated");
                hostedDesignElementTopic.ElementDescription.Input.Clear();
                hostedDesignElementTopic.ElementDescription.Input.SendKeys(designElements.designElement1.Description + "-updated");
                hostedDesignElementTopic.ElementOfficialNo.Input.SendKeys(hostedDesignElementTopic.ElementOfficialNo.Input.Text + "-updated");
                hostedDesignElementTopic.NoOfViews.Input.SendKeys(1.ToString());

                hostedDesignElementTopic.ModalCancel.ClickWithTimeout();
                var modalDiscard = hostedDesignElementTopic.DiscardChangesModal;
                Assert.NotNull(modalDiscard);
                modalDiscard.CancelDiscard();
                hostedDesignElementTopic.ModalApply.ClickWithTimeout();
                driver.WaitForAngular();

                hostedDesignElementTopic.DesignElementsGrid.ClickEdit(0);
                Assert.AreEqual(hostedDesignElementTopic.ClientElementCaseRef.Text, designElements.designElement1.ClientElementId + "-updated");
                Assert.AreEqual(hostedDesignElementTopic.ElementDescription.Text, designElements.designElement1.Description + "-updated");
                Assert.AreEqual(hostedDesignElementTopic.ElementOfficialNo.Text, hostedDesignElementTopic.ElementOfficialNo.Input.Text + "-updated");
                hostedDesignElementTopic.ModalCancel.ClickWithTimeout();
                Assert.False(pageObject.SaveButton.IsDisabled());
                Assert.False(pageObject.RevertButton.IsDisabled());

                hostedDesignElementTopic.DesignElementsGrid.ClickDelete(1);
                Assert.AreEqual(true, hostedDesignElementTopic.DesignElementsGrid.IsRowDeleteMode(1));

                pageObject.SaveButton.Click();
            });

            AssertRequestsIsPoliceImmediately(page);
            page.CallOnRequestDataResponse(new HostedTestPageObject.DataReceivedMessage<bool>("isPoliceImmediately", true));

            driver.DoWithinFrame(() =>
            {
                var pageObject = new HostedTopicPageObject(driver);
                var hostedDesignElementTopic = new CaseDesignElementsTopic(driver);
                Assert.True(pageObject.SaveButton.IsDisabled(), "Saved Successfully if sanity check only warnings");
                Assert.True(pageObject.RevertButton.IsDisabled(), "Saved Successfully if sanity check only warnings");

                Assert.AreEqual(3, hostedDesignElementTopic.DesignElementsGrid.Rows.Count, "Hosted Design Element grid contains 3 records");
                Assert.AreEqual(designElements.designElement1.FirmElementId, hostedDesignElementTopic.DesignElementsGrid.CellText(2, 2));
                Assert.AreEqual(designElements.designElement1.ClientElementId + "-updated", hostedDesignElementTopic.DesignElementsGrid.CellText(2, 3));
                Assert.AreEqual("-updated", hostedDesignElementTopic.DesignElementsGrid.CellText(2, 4));
                Assert.AreEqual(string.Empty, hostedDesignElementTopic.DesignElementsGrid.CellText(2, 5));
                Assert.AreEqual(1.ToString(), hostedDesignElementTopic.DesignElementsGrid.CellText(2, 6));
                Assert.AreEqual(designElements.designElement1.Description + "-updated", hostedDesignElementTopic.DesignElementsGrid.CellText(2, 7));
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedDesignElementSoftAddEditDeleteWithPaging(BrowserType browserType)
        {
            TurnOffDataValidations();

            var setup = new CaseDetailsDbSetup();
            var casesData = setup.NavigationDataSetup();
            var @case = (Case)casesData.Case1;
            setup.GetScreenCriteriaBuilder(@case)
                  .WithTopicControl(KnownCaseScreenTopics.CaseHeader)
                  .WithTopicControl(KnownCaseScreenTopics.DesignElement);
            setup.SetupDesignElementForPaging(@case);

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test");
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case View Design Elements";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(@case.Irn);
            driver.WaitForAngular();

            page.ProgramPicklist.SelectItem(KnownCasePrograms.CaseEntry);
            driver.WaitForAngular();

            page.CaseSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var hostedDesignElementTopic = new CaseDesignElementsTopic(driver);
                Assert.AreEqual(5, hostedDesignElementTopic.DesignElementsGrid.Rows.Count, "Hosted Design Element grid contains 6 records on first page");

                hostedDesignElementTopic.ExpandCollapseIcon.Click();
                Assert.IsNotNull(hostedDesignElementTopic.DesignElementsGrid.Cell(2, 0).FindElement(By.XPath("//a[contains(@class,'k-icon k-minus')]")));
                hostedDesignElementTopic.ExpandCollapseIcon.Click();
                Assert.IsNotNull(hostedDesignElementTopic.DesignElementsGrid.Cell(2, 0).FindElement(By.XPath("//a[contains(@class,'k-icon k-plus')]")));

                hostedDesignElementTopic.DesignElementsGrid.SelectSecondPage();
                driver.WaitForAngular();
                Assert.AreEqual(1, hostedDesignElementTopic.DesignElementsGrid.Rows.Count, "Hosted Design Element grid contains 1 record on second page");
                hostedDesignElementTopic.DesignElementsGrid.SelectFirstPage();
                driver.WaitForAngular();

                var pageSizes = hostedDesignElementTopic.DesignElementsGrid.PageSizes();
                Assert.AreEqual(new[] { "5", "10", "20", "50" }, pageSizes.ToArray());
                driver.WaitForAngular();

                var pageObject = new HostedTopicPageObject(driver);

                hostedDesignElementTopic.DesignElementsGrid.ClickDelete(0);
                Assert.AreEqual(true, hostedDesignElementTopic.DesignElementsGrid.IsRowDeleteMode(0));

                hostedDesignElementTopic.DesignElementsGrid.AddButton.ClickWithTimeout();

                Assert.NotNull(hostedDesignElementTopic.Modal);

                hostedDesignElementTopic.FirmElementCaseRef.Input.SendKeys("111-Firm");
                hostedDesignElementTopic.FirmElementCaseRef.Input.Click();
                hostedDesignElementTopic.AddAnotherCheckbox.Click();
                hostedDesignElementTopic.ModalApply.ClickWithTimeout();
                hostedDesignElementTopic.AddAnotherCheckbox.Click();
                hostedDesignElementTopic.FirmElementCaseRef.Input.SendKeys("112-Firm");
                hostedDesignElementTopic.ModalApply.ClickWithTimeout();

                Assert.AreEqual(7, hostedDesignElementTopic.DesignElementsGrid.Rows.Count, "Hosted Design Element grid contains 7 records on first page");
                Assert.AreEqual("111-Firm", hostedDesignElementTopic.DesignElementsGrid.CellText(5, 2));
                Assert.AreEqual("112-Firm", hostedDesignElementTopic.DesignElementsGrid.CellText(6, 2));

                /* This part will be re-instated by DR-60649
                hostedDesignElementTopic.DesignElementsGrid.ClickEdit(1);
                hostedDesignElementTopic.FirmElementCaseRef.Input.Clear();
                hostedDesignElementTopic.FirmElementCaseRef.Input.SendKeys("Firm-Updated");
                hostedDesignElementTopic.ClientElementCaseRef.Input.Click();
                hostedDesignElementTopic.ModalApply.ClickWithTimeout();
                */

                hostedDesignElementTopic.ExpandCollapseIcon.Click();
                hostedDesignElementTopic.DesignElementsGrid.SelectSecondPage();
                driver.WaitForAngular();
                Assert.AreEqual(1, hostedDesignElementTopic.DesignElementsGrid.Rows.Count, "Hosted Design Element grid contains 1 record on second page");
                hostedDesignElementTopic.DesignElementsGrid.AddButton.ClickWithTimeout();

                hostedDesignElementTopic.FirmElementCaseRef.Input.SendKeys("111-Page2");
                hostedDesignElementTopic.FirmElementCaseRef.Input.Click();
                hostedDesignElementTopic.AddAnotherCheckbox.Click();
                hostedDesignElementTopic.ModalApply.ClickWithTimeout();
                hostedDesignElementTopic.AddAnotherCheckbox.Click();
                hostedDesignElementTopic.FirmElementCaseRef.Input.SendKeys("112-Page2");
                hostedDesignElementTopic.ModalApply.ClickWithTimeout();
                Assert.IsNotNull(hostedDesignElementTopic.DesignElementsGrid.Cell(2, 0).FindElement(By.XPath("//a[contains(@class,'k-icon k-minus')]")));
                hostedDesignElementTopic.ExpandCollapseIcon.Click();
                Assert.AreEqual(9, hostedDesignElementTopic.DesignElementsGrid.Rows.Count, "Hosted Design Element grid contains 9 records on first page");
                Assert.AreEqual(true, hostedDesignElementTopic.DesignElementsGrid.IsRowDeleteMode(0));
                Assert.AreEqual("111-Firm", hostedDesignElementTopic.DesignElementsGrid.CellText(5, 2));
                Assert.AreEqual("112-Firm", hostedDesignElementTopic.DesignElementsGrid.CellText(6, 2));
                Assert.AreEqual("111-Page2", hostedDesignElementTopic.DesignElementsGrid.CellText(7, 2));
                Assert.AreEqual("112-Page2", hostedDesignElementTopic.DesignElementsGrid.CellText(8, 2));
                Assert.AreEqual(true, hostedDesignElementTopic.DesignElementsGrid.IsRowDeleteMode(0));

                pageObject.SaveButton.Click();
            });

            AssertRequestsIsPoliceImmediately(page);
            page.CallOnRequestDataResponse(new HostedTestPageObject.DataReceivedMessage<bool>("isPoliceImmediately", true));

            driver.DoWithinFrame(() =>
            {
                var hostedDesignElementTopic = new CaseDesignElementsTopic(driver);
                Assert.AreEqual(5, hostedDesignElementTopic.DesignElementsGrid.Rows.Count, "Hosted Design Element grid contains 5 records on first page");
                Assert.AreEqual("111-Firm", hostedDesignElementTopic.DesignElementsGrid.CellText(0, 2));
                Assert.AreEqual("111-Page2", hostedDesignElementTopic.DesignElementsGrid.CellText(1, 2));
                hostedDesignElementTopic.DesignElementsGrid.SelectSecondPage();
                driver.WaitForAngular();
                Assert.AreEqual(4, hostedDesignElementTopic.DesignElementsGrid.Rows.Count, "Hosted Design Element grid contains 5 records on second page");
            });
        }

        static void AssertRequestsIsPoliceImmediately(HostedTestPageObject page)
        {
            var requestMessage = page.LifeCycleMessages.Last();
            Assert.AreEqual("isPoliceImmediately", requestMessage.Payload);
            Assert.AreEqual("onRequestData", requestMessage.Action);
        }
    }
}
