using System;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.AffectedCases
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedAffectedCasesComponent : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedAffectedCasesComponentLifecycle(BrowserType browserType)
        {
            var setup = new CaseAffectedCasesDbSetup();
            var data = setup.CaseAffectedCasesSetup();
            setup.GetScreenCriteriaBuilder(data.affectedCase)
                 .WithTopicControl(KnownCaseScreenTopics.CaseHeader)
                 .WithTopicControl(KnownCaseScreenTopics.AffectedCases);

            var driver = TestInitialSteps(browserType, data.affectedCase.Irn);
            var affectedCasesTopic = new CaseAffectedCasesTopic(driver);

            driver.DoWithinFrame(() =>
            {
                Assert.AreEqual(4, affectedCasesTopic.AffectedCasesGrid.Rows.Count, "Hosted Affected Cases grid contains 4 records");
                driver.WaitForAngular();

                Assert.AreEqual(true, affectedCasesTopic.RecordalSteps.IsVisible());
                affectedCasesTopic.RecordalSteps.Click();
                Assert.NotNull(affectedCasesTopic.Modal);
                affectedCasesTopic.ModalCancel.ClickWithTimeout();
                Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.CssSelector(".modal-dialog")), "Ensure recordal steps modal is not visible");
                affectedCasesTopic.RecordalSteps.Click();
                Assert.AreEqual(true, affectedCasesTopic.RecordalStepsGrid.Grid.Displayed);
                Assert.AreEqual(true, affectedCasesTopic.RecordalStepElementsGrid.Grid.Displayed);
                Assert.AreEqual(2, affectedCasesTopic.RecordalStepsGrid.Rows.Count);
                Assert.AreEqual(2, affectedCasesTopic.RecordalStepElementsGrid.Rows.Count);
                affectedCasesTopic.RecordalStepsGrid.ClickRow(1);
                Assert.AreEqual(1, affectedCasesTopic.RecordalStepElementsGrid.Rows.Count);
                affectedCasesTopic.RecordalStepsGrid.ClickRow(0);
                affectedCasesTopic.RecordalStepsGrid.AddButton.ClickWithTimeout();
                Assert.AreEqual(3, affectedCasesTopic.RecordalStepsGrid.Rows.Count);
                var typeAhead = affectedCasesTopic.RecordalStepsGrid.Cell(2, 2).FindElement(By.ClassName("typeahead"));
                typeAhead.SendKeys(data.recordalType1.RecordalTypeName);
                Assert.NotNull(driver.FindElement(By.XPath("//ipx-typeahead/div[1]/span[3]/span[1]")));
                typeAhead.Clear();
                typeAhead.SendKeys(data.recordalType2.RecordalTypeName);
                typeAhead.Click();
                driver.WaitForAngular();
                affectedCasesTopic.RecordalStepsGrid.ClickRow(2);
                driver.WaitForAngular();
                Assert.NotNull(affectedCasesTopic.Modal);
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedAffectedCasesSetAgent(BrowserType browserType)
        {
            var setup = new CaseAffectedCasesDbSetup();
            var data = setup.CaseAffectedCasesSetup();
            setup.GetScreenCriteriaBuilder(data.affectedCase)
                 .WithTopicControl(KnownCaseScreenTopics.CaseHeader)
                 .WithTopicControl(KnownCaseScreenTopics.AffectedCases);

            var driver = TestInitialSteps(browserType, data.affectedCase.Irn);
            var affectedCasesTopic = new CaseAffectedCasesTopic(driver);

            driver.DoWithinFrame(() =>
            {
                var popup = new CommonPopups(driver);
                // Set Agent
                Assert.AreEqual(4, affectedCasesTopic.AffectedCasesGrid.Rows.Count, "Hosted Affected Cases grid contains 4 records");
                driver.WaitForAngular();
                var gncMenu = affectedCasesTopic.SetAgentMenu;
                Assert.IsTrue(gncMenu.Disabled());
                affectedCasesTopic.AffectedCasesGrid.SelectRow(1);
                Assert.IsFalse(gncMenu.Disabled());
                gncMenu.WithJs().Click();
                Assert.NotNull(affectedCasesTopic.Modal);

                Assert.AreEqual(true, affectedCasesTopic.SetAgentsGrid.Grid.Displayed);
                Assert.AreEqual(1, affectedCasesTopic.SetAgentsGrid.Rows.Count);
                Assert.True(affectedCasesTopic.IsCaseNameCheckbox.IsChecked);

                affectedCasesTopic.AgentPicklist.EnterAndSelect("ABCD");
                Assert.True(affectedCasesTopic.ModalSave.Enabled);

                affectedCasesTopic.ModalSave.Click();
                driver.WaitForAngular();
                Assert.NotNull(popup.AlertModal);
                affectedCasesTopic.BtnOk.ClickWithTimeout();
                driver.WaitForAngular();
                //Clear Agent
                var gncClearMenu = affectedCasesTopic.ClearAgentMenu;
                Assert.IsTrue(gncClearMenu.Disabled());
                affectedCasesTopic.AffectedCasesGrid.SelectRow(1);
                Assert.IsFalse(gncClearMenu.Disabled());
                gncClearMenu.WithJs().Click();
                driver.WaitForAngular();
                Assert.NotNull(popup.ConfirmModal);
                popup.ConfirmModal.Proceed();
                driver.WaitForAngular();
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedDeleteAndMaintainAffectedCases(BrowserType browserType)
        {
            var setup = new CaseAffectedCasesDbSetup();
            var data = setup.CaseAffectedCasesSetup(true);
            setup.GetScreenCriteriaBuilder(data.affectedCase)
                 .WithTopicControl(KnownCaseScreenTopics.CaseHeader)
                 .WithTopicControl(KnownCaseScreenTopics.AffectedCases);

            var driver = TestInitialSteps(browserType, data.affectedCase.Irn);
            var affectedCasesTopic = new CaseAffectedCasesTopic(driver);
            driver.DoWithinFrame(() =>
            {
                var pageObject = new HostedTopicPageObject(driver);
                Assert.True(pageObject.SaveButton.IsDisabled());
                Assert.True(pageObject.RevertButton.IsDisabled());
                Assert.AreEqual(4, affectedCasesTopic.AffectedCasesGrid.Rows.Count, "Hosted Affected Cases grid contains 4 records");
                driver.WaitForAngular();
                var gncMenu = affectedCasesTopic.DeleteAffectedCasesMenu;
                Assert.IsTrue(gncMenu.Disabled());
                affectedCasesTopic.AffectedCasesGrid.SelectRow(1);
                Assert.IsFalse(gncMenu.Disabled());
                gncMenu.WithJs().Click();
                driver.FindElement(By.CssSelector(".buttons > button:nth-child(1)")).ClickWithTimeout();
                Assert.AreEqual(4, affectedCasesTopic.AffectedCasesGrid.Rows.Count, "Hosted Affected Cases grid contains 4 records");
                gncMenu.WithJs().Click();
                driver.FindElement(By.CssSelector(".buttons > button:nth-child(2)")).ClickWithTimeout();
                driver.WaitForAngular();
                affectedCasesTopic.CheckBox1.ClickWithTimeout();
                driver.WaitForAngular();
                Assert.False(pageObject.SaveButton.IsDisabled());
                Assert.False(pageObject.RevertButton.IsDisabled());
                pageObject.SaveButton.Click();
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie, Ignore = "Known checkbox issue with IE.")]
        public void TestHostedAddAffectedCases(BrowserType browserType)
        {
            var setup = new CaseAffectedCasesDbSetup();
            var data = setup.CaseAffectedCasesSetup();
            setup.GetScreenCriteriaBuilder(data.affectedCase)
                 .WithTopicControl(KnownCaseScreenTopics.CaseHeader)
                 .WithTopicControl(KnownCaseScreenTopics.AffectedCases);
            var driver = TestInitialSteps(browserType, data.affectedCase.Irn);
            var affectedCasesTopic = new CaseAffectedCasesTopic(driver);

            driver.DoWithinFrame(() =>
            {
                affectedCasesTopic.BtnAddAffectedCases.Click();
                driver.WaitForAngular();
                Assert.NotNull(affectedCasesTopic.Modal);
                affectedCasesTopic.PicklistJurisdiction.Typeahead.Click();
                affectedCasesTopic.PicklistJurisdiction.Typeahead.SendKeys("AUSTR");
                affectedCasesTopic.TxtOfficialNo.Input.SendKeys("213442");
                affectedCasesTopic.ChkBoxStep1.Click();
                var count = affectedCasesTopic.AffectedCasesGrid.Rows.Count;
                affectedCasesTopic.BtnSaveAffectedCases.ClickWithTimeout();
                driver.WaitForAngular();
                Assert.Less(count, affectedCasesTopic.AffectedCasesGrid.Rows.Count);
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedAffectedCasesRecordalRequest(BrowserType browserType)
        {
            var setup = new CaseAffectedCasesDbSetup();
            var data = setup.CaseAffectedCasesSetup(true);
            setup.GetScreenCriteriaBuilder(data.affectedCase)
                 .WithTopicControl(KnownCaseScreenTopics.CaseHeader)
                 .WithTopicControl(KnownCaseScreenTopics.AffectedCases);

            var driver = TestInitialSteps(browserType, data.affectedCase.Irn);
            var affectedCasesTopic = new CaseAffectedCasesTopic(driver);

            driver.DoWithinFrame(() =>
            {
                Assert.AreEqual(4, affectedCasesTopic.AffectedCasesGrid.Rows.Count, "Hosted Affected Cases grid contains 4 records");
                driver.WaitForAngular();
                var gncMenu = affectedCasesTopic.RequestRecordalMenu;
                Assert.IsTrue(gncMenu.Disabled());
                affectedCasesTopic.AffectedCasesGrid.SelectRow(1);
                Assert.IsFalse(gncMenu.Disabled());
                gncMenu.WithJs().Click();
                Assert.AreEqual(true, affectedCasesTopic.RequestRecordalGrid.Grid.Displayed);
                Assert.AreEqual(1, affectedCasesTopic.RequestRecordalGrid.Rows.Count);

                Assert.AreEqual(affectedCasesTopic.ModalTitle.Text, "Request Recordal");
                RequestAndRejectRecordals(affectedCasesTopic, driver, gncMenu);
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedAffectedCasesApplyRecordal(BrowserType browserType)
        {
            var setup = new CaseAffectedCasesDbSetup();
            var data = setup.CaseAffectedCasesSetup(true);
            setup.GetScreenCriteriaBuilder(data.affectedCase)
                 .WithTopicControl(KnownCaseScreenTopics.CaseHeader)
                 .WithTopicControl(KnownCaseScreenTopics.AffectedCases);

            var driver = TestInitialSteps(browserType, data.affectedCase.Irn);
            var affectedCasesTopic = new CaseAffectedCasesTopic(driver);

            driver.DoWithinFrame(() =>
            {
                Assert.AreEqual(4, affectedCasesTopic.AffectedCasesGrid.Rows.Count, "Hosted Affected Cases grid contains 4 records");
                driver.WaitForAngular();
                var gncMenu = affectedCasesTopic.ApplyRecordalMenu;
                Assert.IsTrue(gncMenu.Disabled());
                affectedCasesTopic.AffectedCasesGrid.SelectRow(1);
                Assert.IsFalse(gncMenu.Disabled());
                gncMenu.WithJs().Click();
                Assert.NotNull(affectedCasesTopic.Modal);
                Assert.AreEqual(true, affectedCasesTopic.RequestRecordalGrid.Grid.Displayed);
                Assert.AreEqual(1, affectedCasesTopic.RequestRecordalGrid.Rows.Count);
                Assert.AreEqual(affectedCasesTopic.ModalTitle.Text, "Apply Recordal");
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedAffectedCasesRejectRecordal(BrowserType browserType)
        {
            var setup = new CaseAffectedCasesDbSetup();
            var data = setup.CaseAffectedCasesSetup(true);
            setup.GetScreenCriteriaBuilder(data.affectedCase)
                 .WithTopicControl(KnownCaseScreenTopics.CaseHeader)
                 .WithTopicControl(KnownCaseScreenTopics.AffectedCases);

            var driver = TestInitialSteps(browserType, data.affectedCase.Irn);
            var affectedCasesTopic = new CaseAffectedCasesTopic(driver);

            driver.DoWithinFrame(() =>
            {
                Assert.AreEqual(4, affectedCasesTopic.AffectedCasesGrid.Rows.Count, "Hosted Affected Cases grid contains 4 records");
                driver.WaitForAngular();
                var gncMenu = affectedCasesTopic.RejectRecordalMenu;
                Assert.IsTrue(gncMenu.Disabled());
                affectedCasesTopic.AffectedCasesGrid.SelectRow(1);
                Assert.IsFalse(gncMenu.Disabled());
                gncMenu.WithJs().Click();
                Assert.NotNull(affectedCasesTopic.Modal);
                Assert.AreEqual(true, affectedCasesTopic.RequestRecordalGrid.Grid.Displayed);
                Assert.AreEqual(1, affectedCasesTopic.RequestRecordalGrid.Rows.Count);

                Assert.AreEqual(affectedCasesTopic.ModalTitle.Text, "Reject Recordal");
                RequestAndRejectRecordals(affectedCasesTopic, driver, gncMenu);
            });
        }

        void RequestAndRejectRecordals(CaseAffectedCasesTopic affectedCasesTopic, NgWebDriver driver, NgWebElement gncMenu)
        {
            var popup = new CommonPopups(driver);

            Assert.AreEqual(affectedCasesTopic.TxtRequestDate.Input.WithJs().GetValue(), DateTime.Now.ToString("dd-MMM-yyyy"));
            Assert.False(affectedCasesTopic.ModalSave.IsDisabled());

            affectedCasesTopic.TxtRequestDate.Input.Clear();
            Assert.AreEqual(affectedCasesTopic.TxtRequestDate.Input.WithJs().GetValue(), string.Empty);
            Assert.True(affectedCasesTopic.Error.Displayed);
            Assert.True(affectedCasesTopic.ModalSave.IsDisabled());
            driver.WaitForAngular();
            affectedCasesTopic.ModalCancel.ClickWithTimeout();
            driver.WaitForAngular();
            gncMenu.WithJs().Click();
            Assert.False(affectedCasesTopic.ModalSave.IsDisabled());
            affectedCasesTopic.ModalSave.Click();
            driver.WaitForAngular();
            Assert.NotNull(popup.AlertModal);
        }

        NgWebDriver TestInitialSteps(BrowserType browserType, string irn)
        {
            var driver = BrowserProvider.Get(browserType);
            var user = new Users().WithPermission(ApplicationTask.MaintainCase, Allow.Select).Create();
            SignIn(driver, "/#/deve2e/hosted-test", user.Username, user.Password);
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case Affected Cases";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(irn);
            driver.WaitForAngular();

            page.ProgramPicklist.SelectItem(KnownCasePrograms.CaseEntry);
            driver.WaitForAngular();

            page.CaseSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");
            return driver;
        }
    }
}
