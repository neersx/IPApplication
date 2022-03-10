using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseAffectedCases : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AffectedCases(BrowserType browserType)
        {
            var setup = new CaseAffectedCasesDbSetup();
            var data = setup.CaseAffectedCasesSetup();
            setup.GetScreenCriteriaBuilder(data.affectedCase)
                .WithTopicControl(InprotechKaizen.Model.KnownCaseScreenTopics.CaseHeader)
                .WithTopicControl(InprotechKaizen.Model.KnownCaseScreenTopics.AssignedCases);
            var driver = BrowserProvider.Get(browserType);
            var user = new Users().WithPermission(ApplicationTask.MaintainCase, Allow.Select)
                                  .Create();
            SignIn(driver, $"/#/caseview/{data.affectedCase.Id}", user.Username, user.Password);

            var affectedCasesTopic = new CaseAffectedCasesTopic(driver);
            affectedCasesTopic.AffectedCasesGrid.Grid.WithJs().ScrollIntoView();
            Assert.AreEqual(4, affectedCasesTopic.AffectedCasesGrid.Rows.Count);

            Assert.AreEqual(false, affectedCasesTopic.ToggleRecordalStepStatus.IsChecked());
            Assert.AreEqual(9, affectedCasesTopic.AffectedCasesGrid.Headers.Count);
            affectedCasesTopic.ToggleRecordalStepStatus.Click();
            Assert.AreEqual(11, affectedCasesTopic.AffectedCasesGrid.Headers.Count);

            Assert.AreEqual(true, affectedCasesTopic.RecordalSteps.IsVisible());
            Assert.AreEqual(false, affectedCasesTopic.RecordalSteps.IsDisabled());

            affectedCasesTopic.RecordalSteps.Click();
            Assert.NotNull(affectedCasesTopic.Modal);
            Assert.AreEqual(true, affectedCasesTopic.RecordalStepsGrid.Grid.Displayed);
            Assert.AreEqual(2, affectedCasesTopic.RecordalStepsGrid.Rows.Count);
            Assert.AreEqual(true, affectedCasesTopic.RecordalStepElementsGrid.Grid.Displayed);
            Assert.AreEqual(2, affectedCasesTopic.RecordalStepElementsGrid.Rows.Count);
            affectedCasesTopic.RecordalStepsGrid.ClickRow(1);
            Assert.AreEqual(1, affectedCasesTopic.RecordalStepElementsGrid.Rows.Count);
            affectedCasesTopic.RecordalStepsGrid.ClickRow(0);
            Assert.AreEqual(2, affectedCasesTopic.RecordalStepElementsGrid.Rows.Count);

            affectedCasesTopic.ModalCancel.ClickWithTimeout();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.CssSelector(".modal-dialog")), "Ensure recordal steps modal is not visible");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AffectedCasesFilters(BrowserType browserType)
        {
            var setup = new CaseAffectedCasesDbSetup();
            var data = setup.CaseAffectedCasesSetup();
            setup.GetScreenCriteriaBuilder(data.affectedCase)
                .WithTopicControl(InprotechKaizen.Model.KnownCaseScreenTopics.CaseHeader)
                .WithTopicControl(InprotechKaizen.Model.KnownCaseScreenTopics.AssignedCases);
            var driver = BrowserProvider.Get(browserType);
            var user = new Users().WithPermission(ApplicationTask.MaintainCase, Allow.Select)
                                  .Create();
            SignIn(driver, $"/#/caseview/{data.affectedCase.Id}", user.Username, user.Password);

            var affectedCasesTopic = new CaseAffectedCasesTopic(driver);
            affectedCasesTopic.AffectedCasesGrid.Grid.WithJs().ScrollIntoView();
            var originalCount = 4;
            Assert.AreEqual(originalCount, affectedCasesTopic.AffectedCasesGrid.Rows.Count);
            Assert.AreEqual(true, affectedCasesTopic.BtnAffectedCasesFilter.IsVisible());

            affectedCasesTopic.BtnAffectedCasesFilter.Click();
            Assert.AreEqual(true, affectedCasesTopic.AffectedCasesFilterPanel.Displayed);
            driver.WaitForAngular();
            affectedCasesTopic.BtnApplyFilter.WithJs().ScrollIntoView();
            affectedCasesTopic.BtnApplyFilter.Click();
            Assert.AreEqual(originalCount, affectedCasesTopic.AffectedCasesGrid.Rows.Count);
            Assert.AreEqual(true, affectedCasesTopic.AffectedCasesFilterPanel.Displayed);

            affectedCasesTopic.PicklistJurisdiction.Typeahead.Click();
            affectedCasesTopic.PicklistJurisdiction.Typeahead.SendKeys("c");
            affectedCasesTopic.PicklistPropertyType.Typeahead.WithJs().Focus();
            affectedCasesTopic.PicklistPropertyType.Typeahead.SendKeys("p");
            affectedCasesTopic.PicklistCurrentOwner.Typeahead.WithJs().Focus();
            affectedCasesTopic.TxtCaseRef.Input.SendKeys("irn");
            affectedCasesTopic.TxtStepNo.Input.SendKeys("step 1");
            affectedCasesTopic.TxtOfficialNo.Input.WithJs().Focus();
            affectedCasesTopic.TxtOfficialNo.Input.SendKeys("77");
            affectedCasesTopic.ChkBoxRecordalStatusRecorded.Click();
            driver.WaitForAngular();
            affectedCasesTopic.BtnApplyFilter.WithJs().Click();
            driver.WaitForAngular();
            Assert.AreEqual(0, affectedCasesTopic.AffectedCasesGrid.Rows.Count);
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Id("filterPanel")), "Filter panel is not visible");

            affectedCasesTopic.BtnAffectedCasesFilter.Click();
            Assert.AreEqual(true, affectedCasesTopic.AffectedCasesFilterPanel.Displayed);
            Assert.AreEqual("irn", affectedCasesTopic.TxtCaseRef.Text);
            Assert.AreEqual("step 1", affectedCasesTopic.TxtStepNo.Text);
            affectedCasesTopic.BtnClearFilter.WithJs().ScrollIntoView();
            affectedCasesTopic.BtnClearFilter.Click();
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            Assert.AreEqual(4, affectedCasesTopic.AffectedCasesGrid.Rows.Count);
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Id("filterPanel")), "Filter panel is not visible");

            affectedCasesTopic.BtnAffectedCasesFilter.Click();
            Assert.AreEqual(true, affectedCasesTopic.AffectedCasesFilterPanel.Displayed);
            Assert.AreEqual(string.Empty, affectedCasesTopic.TxtCaseRef.Text);
            Assert.AreEqual(string.Empty, affectedCasesTopic.TxtStepNo.Text);
            Assert.AreEqual(false, affectedCasesTopic.ChkBoxRecordalStatusRecorded.IsChecked());
            Assert.AreEqual(false, affectedCasesTopic.ChkBoxCaseStatusPending.IsChecked());
        }

    }
}
