using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.HostedComponents;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Accounting.Work;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.SplitWip
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedSplitWips : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _wipData = new SplitWipDbSetUp().ForSplitWip();
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();
        }

        WorkInProgress _wipData;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void WipSplit(BrowserType browserType)
        {
            var componentName = "Hosted Split Wip";

            var user = new Users()
                       .WithPermission(ApplicationTask.AdjustWip)
                       .WithPermission(ApplicationTask.MaintainTimeViaTimeRecording)
                       .WithPermission(ApplicationTask.RecordWip).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test", user.Username, user.Password);

            driver.With<HostedTestPageObject>(hostedPage =>
            {
                hostedPage.ComponentDropdown.Text = componentName;
                driver.WaitForAngular();

                hostedPage.EntityIdTextField.Text = _wipData.EntityId.ToString();
                driver.WaitForAngular();
                hostedPage.TransKeyTextField.Text = _wipData.TransactionId.ToString();
                driver.WaitForAngular();
                hostedPage.WipSeqKeyTextField.Text = _wipData.WipSequenceNo.ToString();
                driver.WaitForAngular();
                hostedPage.LoadSplitWip.Click();
                driver.WaitForAngular();

                hostedPage.WaitForLifeCycleAction("onInit");
                hostedPage.WaitForLifeCycleAction("onViewInit");

                driver.DoWithinFrame(() =>
                {
                    var page = new SplitWipPageObjects(driver);

                    page.CasePicklist.Typeahead.SendKeys(_wipData.Case.Irn);
                    page.CasePicklist.Typeahead.SendKeys(Keys.ArrowDown);
                    page.CasePicklist.Typeahead.SendKeys(Keys.Enter);
                   
                    page.Amount.Input.Clear();
                    page.Amount.Input.SendKeys("500");
                    page.Reason.Input.SelectByIndex(1);
                    Assert.False(page.SplitPercent.Input.Enabled);
                    Assert.AreEqual("50.00", page.SplitPercent.Number, "Split Percentage should be 50");
                    page.ApplyButton.Click();
                    Assert.True(page.SaveButton.IsDisabled());

                    page.CasePicklist.Typeahead.SendKeys(_wipData.Case.Irn);
                    page.CasePicklist.Typeahead.SendKeys(Keys.ArrowDown);
                    page.CasePicklist.Typeahead.SendKeys(Keys.Enter);
                    page.Amount.Input.SendKeys("100.00");
                    page.AllocateRemainder.Click();
                    Assert.True(page.Amount.Number.Contains("500"), "Amount should be 500");
                    Assert.AreEqual("50.00", page.SplitPercent.Number, "Split Percentage should be 50");
                    page.ApplyButton.Click();
                    Assert.AreEqual(2, page.SplitWipGrid.Rows.Count);
                    Assert.False(page.SaveButton.IsDisabled());

                    page.SaveButton.Click();
                    var popups = new CommonPopups(driver);
                    Assert.NotNull(popups.ConfirmModal, "Success message will be displayed");
                    popups.ConfirmModal.Ok();
                });
            });
        }
    }
}
