using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.HostedComponents;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Accounting.Work;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.WipAdjustments
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedWipAdjustments : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _wipData = new WipAdjustmentsDbSetup().ForWipAdjustments();
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
        public void WipAdjustment(BrowserType browserType)
        {
            var componentName = "Hosted Adjust Wip";

            var user = new Users()
                       .WithPermission(ApplicationTask.AdjustWip)
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
                hostedPage.LoadWipAdjustment.Click();
                driver.WaitForAngular();

                hostedPage.WaitForLifeCycleAction("onInit");
                hostedPage.WaitForLifeCycleAction("onViewInit");

                driver.DoWithinFrame(() =>
                {
                    var page = new WipAdjustmentsPageObject(driver);

                    Assert.True(page.DebitRadioButton.IsChecked);
                    Assert.False(page.CreditRadioButton.IsChecked);
                    Assert.False(page.NarrativeRadioButton.IsChecked);
                    Assert.False(page.StaffRadioButton.IsChecked);
                    Assert.True(page.TransactionDate.Input.Enabled);
                    Assert.True(page.LocalValue.Input.Enabled);
                    Assert.True(page.LocalAdjustmentValue.Input.Enabled);
                    Assert.True(page.ForeignValue.Input.Enabled);
                    Assert.False(page.CurrentForeignValue.Input.Enabled);
                    Assert.False(page.CurrentLocalValue.Input.Enabled);
                    Assert.True(page.SaveButton.IsDisabled());
                    Assert.True(page.ButtonClose.Enabled);
                    Assert.False(page.StaffPicklist.Enabled);

                    page.StaffRadioButton.Click();
                    Assert.False(page.LocalValue.Input.Enabled);
                    Assert.False(page.LocalAdjustmentValue.Input.Enabled);
                    Assert.False(page.ForeignValue.Input.Enabled);
                    Assert.True(page.StaffPicklist.Enabled);

                    page.NarrativeRadioButton.Click();
                    Assert.False(page.LocalValue.Input.Enabled);
                    Assert.False(page.LocalAdjustmentValue.Input.Enabled);
                    Assert.False(page.ForeignValue.Input.Enabled);
                    Assert.False(page.StaffPicklist.Enabled);

                    page.DebitRadioButton.Click();
                    page.LocalAdjustmentValue.Input.SendKeys("-200");
                    driver.WaitForAngular();
                    Assert.False(page.DebitRadioButton.Input.IsChecked());
                    Assert.True(page.CreditRadioButton.Input.IsChecked());
                    page.Reason.Input.SelectByIndex(1);
                    Assert.False(page.SaveButton.IsDisabled());

                    page.NarrativeRadioButton.Click();
                    page.SaveButton.Click();
                    Assert.True(page.DebitNoteText.HasError);
                    page.DebitNoteText.Input.SendKeys(Fixture.String(5));
                    page.SaveButton.Click();
                    var popups = new CommonPopups(driver);

                    Assert.NotNull(popups.ConfirmModal, "Success message will be displayed");
                    popups.ConfirmModal.Ok();
                });
            });
        }
    }
}
