using System;
using System.Linq;
using System.Threading;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Accounting.VatReturns;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "HmrcOverride", "http://localhost/e2e/hmrc")]
    public class Vat : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            DbSetup.Do(x =>
            {
                _validEntity = new NameBuilder(x.DbContext).CreateOrg(NameUsedAs.Organisation, "entityA");
                _validEntity.TaxNumber = "123456789";
                var entityB = new NameBuilder(x.DbContext).CreateOrg(NameUsedAs.Organisation, "entityB");
                var entityC = new NameBuilder(x.DbContext).CreateOrg(NameUsedAs.Organisation, "entityC");
                entityC.TaxNumber = _validEntity.TaxNumber;

                x.Insert(new SpecialName(true, _validEntity));
                x.Insert(new SpecialName(true, entityB));
                x.Insert(new SpecialName(true, entityC));

                var settings = new ExternalSettings(KnownExternalSettings.HmrcVatSettings)
                {
                    Settings = "{\"RedirectUri\": \"https://localhost/cpainproma/apps/hmrc/accounting/vat\", \"ClientId\": \"w+7E0JmdLrjPjYR5fjznUA==\", \"ClientSecret\": \"Yfgqlm4kSRBH+0sMzEY71w==\", \"IsProduction\": true, \"HmrcApplicationName\":\"Inprotech-Internal\"}"
                };
                x.Insert(settings);

                _hmrcUser = new Users()
                    .WithPermission(ApplicationTask.HmrcVatSubmission)
                    .WithPermission(ApplicationTask.HmrcSaveSettings)
                    .Create();

                var loginUser = x.DbContext.Set<User>().Single(v => v.Id == _hmrcUser.Id);
                var tokenString = "447PfdM/wM39XjrqPq+ldkA6jeGFu0EhHHFDWOmGSasNx1ah6wFCAXESSIpO7XSs";
                var tokens = new ExternalCredentials(loginUser, "taxDude", tokenString, KnownExternalSettings.HmrcVatSettings + _validEntity.TaxNumber);
                x.Insert(tokens);

                _hmrcVatSettings = new HmrcVatSettings
                {
                    ClientId = "vatUser",
                    ClientSecret = "bigfatvatpassword",
                    RedirectUri = "https://localhost/cpainproma/apps/hmrc/accounting/vat",
                    HmrcApplicationName = "Inprotech-Internal"
                };
            });
        }

        Name _validEntity;
        HmrcVatSettings _hmrcVatSettings;
        TestUser _hmrcUser;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VatSubmissionSearch(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/vat?code=" + Fixture.AlphaNumericString(16), _hmrcUser.Username, _hmrcUser.Password);
            var vatPage = new VatPage(driver);

            Assert.True(vatPage.EntityDropDown.IsDisplayed, "Expected Entity drop down to be displayed on Vat page.");
            Assert.True(vatPage.OpenCheckbox.IsChecked, "Expected that the Open checkbox to be checked by default.");

            vatPage.EntityDropDown.Input.SelectByText("entityBOrg (VRN: -)");
            var error = driver.FindElements(By.ClassName("cpa-icon-exclamation-triangle")).First();

            Assert.True(error.Displayed, "Expect Entities with no Tax Number to display error exclamation.");

            vatPage.EntityDropDown.Input.SelectByText("entityAOrg (VRN: " + _validEntity.TaxNumber + ")");

            Assert.IsTrue(vatPage.TaxCode.Text.Contains("entityCOrg"), "Expect that the same Tax Number entity is displayed when a valid entity is selected.");
            vatPage.OpenCheckbox.Click();

            Assert.False(vatPage.OpenCheckbox.IsChecked, "Expect at least 1 checkbox to be checked.");
            Assert.True(vatPage.FulfilledCheckbox.IsChecked, "Expect at least 1 checkbox to be checked.");

            vatPage.FromDate.Input.SendKeys(DateTime.Now.ToShortDateString());
            vatPage.ToDate.Input.SendKeys(DateTime.Now.AddDays(28).ToShortDateString());
            vatPage.OpenCheckbox.Click();
            vatPage.SubmitButton.Click();

            Assert.IsTrue(vatPage.Obligations.Grid.Displayed, "Expect the grid to be shown when the Submit button is clicked.");
            Assert.IsTrue(vatPage.ResultsTitle.Displayed, "Expect the results header to be displayed when searched");
            Assert.IsTrue(vatPage.ResultsTitle.Text.Contains(_validEntity.TaxNumber), "Expect the selected entity's tax number to be displayed when searched");

            Assert.AreEqual(3, vatPage.Obligations.Rows.Count, "Expected obligations to be displayed in the grid");

            Assert.IsFalse(vatPage.Obligations.ColumnContains(1, By.TagName("span"), 2), "No error logs should exist for initial obligations");
            Assert.AreEqual("open", vatPage.Obligations.CellText(0, "Status").ToLower(), "Expected Open obligation to be displayed first");
            Assert.IsTrue(DateTime.Parse(vatPage.Obligations.CellText(0, "Due Date")) >= DateTime.Parse(vatPage.Obligations.CellText(1, "Due Date")));

            const string errorClass = "text-red-dark tooltip-error ip-hover-help";
            var dueDateClass = vatPage.Obligations.Cell(0, "Due Date").FindElement(By.TagName("span")).GetAttribute("class");
            Assert.IsFalse(dueDateClass.TextContains(errorClass), $"Expected due obligation {dueDateClass} to not indicate error");

            dueDateClass = vatPage.Obligations.Cell(1, "Due Date").FindElement(By.TagName("span")).GetAttribute("class");
            Assert.IsTrue(dueDateClass.TextContains(errorClass), $"Expected past-due obligation {dueDateClass} to indicate error");

            dueDateClass = vatPage.Obligations.Cell(2, "Due Date").FindElement(By.TagName("span")).GetAttribute("class");
            Assert.IsFalse(dueDateClass.TextContains(errorClass), $"Expected fulfilled obligation {dueDateClass} to not indicate error");
            Assert.AreEqual("fulfilled", vatPage.Obligations.CellText(2, "Status").ToLower(), "Expected Fulfilled obligation to be displayed last");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VatSubmissionDialog(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/vat?code=" + Fixture.AlphaNumericString(16), _hmrcUser.Username, _hmrcUser.Password);
            var vatPage = new VatPage(driver);

            vatPage.EntityDropDown.Input.SelectByText("entityAOrg (VRN: " + _validEntity.TaxNumber + ")");
            vatPage.OpenCheckbox.Click();
            vatPage.FromDate.Input.SendKeys(DateTime.Now.ToShortDateString());
            vatPage.ToDate.Input.SendKeys(DateTime.Now.AddDays(28).ToShortDateString());
            vatPage.OpenCheckbox.Click();
            vatPage.SubmitButton.Click();

            vatPage.Obligations.Cell(0, 0).FindElement(By.ClassName("cpa-icon-check-in")).ClickWithTimeout();

            var modal = new VatSubmissionModal(driver);
            Assert.IsTrue(string.Equals("Submit vat return", modal.Title, StringComparison.OrdinalIgnoreCase), "Expect the correct title to be displayed");

            Assert.IsTrue(modal.Declaration.Displayed && !modal.DeclarationCheckbox.IsChecked(), "Expect the declaration checkbox to be displayed and unchecked");
            Assert.IsTrue(modal.SubmitButton.Displayed && modal.SubmitButton.IsDisabled(), "Expect the Submit button to be initially disabled");
            Assert.IsTrue(modal.CancelButton.Displayed && modal.CancelButton.Enabled, "Expect the Cancel button to always be enabled");
            Assert.IsTrue(modal.HeaderDescriptionSpan.Text.Contains("entityCOrg"), "Expect that the same Tax Number entity is displayed when such tax number is selected.");

            modal.Declaration.Click();
            Assert.IsTrue(modal.SubmitButton.Enabled, "Expect the Submit button to be enabled after accepting declaration");

            modal.Declaration.Click();
            Assert.IsTrue(modal.SubmitButton.IsDisabled(), "Expect the Submit button to be disabled after un-checking declaration");

            modal.Declaration.Click();
            modal.SubmitButton.ClickWithTimeout();

            Assert.IsTrue(modal.Declaration.Displayed && modal.DeclarationCheckbox.IsChecked() && modal.DeclarationCheckbox.IsDisabled(), "Expect the declaration checkbox to be disabled after submitting");
            Assert.IsTrue(modal.SubmitButton.Displayed && modal.SubmitButton.IsDisabled(), "Expect the Submit button to be disabled after submitting");

            modal.Close();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VatReturnDialog(BrowserType browserType)
        {
            DbSetup.Do(x =>
                       {
                           x.Insert(new VatReturn
                           {
                               Data = $"{{\"processingDate\":\"{DateTime.Now:s}\",\"paymentIndicator\":\"BANK\",\"formBundleNumber\":\"256660290587\",\"chargeRefNumber\":\"aCxFaNx0FZsCvyWF\"}}",
                               PeriodId = "18A3",
                               EntityId = _validEntity.Id,
                               IsSubmitted = true,
                               TaxNumber = "123456789"
                           });
                       });
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/vat?code=" + Fixture.AlphaNumericString(16), _hmrcUser.Username, _hmrcUser.Password);
            var vatPage = new VatPage(driver);

            vatPage.EntityDropDown.Input.SelectByText("entityAOrg (VRN: " + _validEntity.TaxNumber + ")");
            vatPage.OpenCheckbox.Click();
            vatPage.FromDate.Input.SendKeys(DateTime.Now.ToShortDateString());
            vatPage.ToDate.Input.SendKeys(DateTime.Now.AddDays(28).ToShortDateString());
            vatPage.OpenCheckbox.Click();
            vatPage.SubmitButton.Click();
            vatPage.Obligations.Cell(2, 0).FindElement(By.ClassName("cpa-icon-file")).ClickWithTimeout();

            var modal = new VatSubmissionModal(driver);
            Assert.IsTrue(string.Equals("Submitted VAT Details", modal.Title, StringComparison.OrdinalIgnoreCase), "Expect the correct title to be displayed");
            Assert.Throws<NoSuchElementException>(() => modal.FindElement(By.CssSelector("div#accountingVatFulfilled ip-checkbox div.input-wrap label")), "Expect the declaration checkbox to be unavailable");
            Assert.Throws<NoSuchElementException>(() => modal.FindElement(By.CssSelector("div#accountingVatFulfilled div.modal-footer button.btn-primary")), "Expect the Submit button to be unavailable");
            Assert.IsTrue(modal.FindElement(By.CssSelector("div.alert-success")).Displayed, "Expect the stored response to be displayed");
            Assert.IsTrue(modal.ExportButton.Enabled);

            modal.ExportButton.Click();
            var windowCount = driver.WindowHandles.Count;
            Assert.AreEqual(2, windowCount, "Ensure a new window is opened.");
        }

        [TestCase(BrowserType.Chrome, Ignore = "Flakey - To Be Resolved")]
        [TestCase(BrowserType.FireFox, Ignore = "Flakey - To Be Resolved")]
        [TestCase(BrowserType.Ie, Ignore = "Flakey - To Be Resolved")]
        public void VatSubmissionErrorLogs(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                x.Insert(new VatReturn
                {
                    Data = "{ \"code\": \"ERROR\", \"message\": \"There was an error.\"}",
                    PeriodId = "18A1",
                    EntityId = _validEntity.Id,
                    TaxNumber = "123456789"
                });
                
                Thread.Sleep(1);//On faster systems the underlying data type of datetime can sometimes be equal and so the order of the records returned is wrong.

                x.Insert(new VatReturn
                {
                    Data = "{ \"code\": \"ERROR\", \"message\": \"There was a newer error.\"}",
                    PeriodId = "18A1",
                    EntityId = _validEntity.Id,
                    TaxNumber = "123456789"
                });
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/vat?code=" + Fixture.AlphaNumericString(16), _hmrcUser.Username, _hmrcUser.Password);
            var vatPage = new VatPage(driver);

            vatPage.EntityDropDown.Input.SelectByText("entityAOrg (VRN: " + _validEntity.TaxNumber + ")");
            driver.WaitForAngular();
            vatPage.FromDate.Input.SendKeys(DateTime.Now.ToShortDateString());
            driver.WaitForAngular();
            vatPage.ToDate.Input.SendKeys(DateTime.Now.AddDays(28).ToShortDateString());
            driver.WaitForAngular();
            vatPage.FulfilledCheckbox.Click();
            vatPage.SubmitButton.Click();
            Assert.IsTrue(vatPage.Obligations.ColumnContains(1, By.ClassName("cpa-icon-history"), 3), "Expect table to display error log icon");
            Assert.Throws<NoSuchElementException>(() => vatPage.Obligations.Cell(0, 1).FindElement(By.ClassName("cpa-icon-history")), "Expect first open obligation to not have error log");
            Assert.Throws<NoSuchElementException>(() => vatPage.Obligations.Cell(2, 1).FindElement(By.ClassName("cpa-icon-history")), "Expect first fulfilled obligation to not have error log");

            vatPage.Obligations.ReturnFirstCellContaining(1, By.ClassName("cpa-icon-history")).ClickWithTimeout();

            var modal = new VatSubmissionModal(driver);
            Assert.IsTrue(string.Equals("vat error log", modal.Title, StringComparison.OrdinalIgnoreCase), "Expect the correct title to be displayed");
            var errors = new KendoGrid(driver, "vat-error-log");
            var errorMessage = errors.CellText(0, 1);
            Assert.IsTrue(errorMessage.IgnoreCaseContains("there was a newer error"), $"Expected \"there was a newer error\" in [{errorMessage}]");
            errorMessage = errors.CellText(1, 1);
            Assert.IsTrue(errorMessage.IgnoreCaseContains("there was an error"), $"Expected \"there was an error\" in [{errorMessage}]");
            modal.Close();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ConfigureHmrcSettings(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/vat", _hmrcUser.Username, _hmrcUser.Password);
            var vatPage = new VatPage(driver);
            vatPage.ConfigureSettings.Click();

            var hmrcSettingsPage = new HmrcSettingsPage(driver);
            var productionRadioButton = driver.FindRadio("production");
            var demoRadioButton = driver.FindRadio("demo");

            Assert.True(hmrcSettingsPage.ClientSecret.Value.IsNullOrEmpty());
            Assert.True(productionRadioButton.IsChecked);
            Assert.False(demoRadioButton.IsChecked);
            Assert.AreEqual(hmrcSettingsPage.ClientId.Value, _hmrcVatSettings.ClientId);
            Assert.AreEqual(hmrcSettingsPage.RedirctUri.Value, _hmrcVatSettings.RedirectUri);
            Assert.AreEqual(hmrcSettingsPage.HmrcApplicationName.Value, _hmrcVatSettings.HmrcApplicationName);

            hmrcSettingsPage.ClientSecret.Clear();
            hmrcSettingsPage.ClientId.Clear();
            hmrcSettingsPage.RedirctUri.Clear();
            hmrcSettingsPage.HmrcApplicationName.Clear();

            hmrcSettingsPage.DiscardButton.Click();
            var popups = new CommonPopups(driver);
            popups.DiscardChangesModal.Discard();

            Assert.AreEqual(hmrcSettingsPage.ClientId.Value, _hmrcVatSettings.ClientId);
            Assert.AreEqual(hmrcSettingsPage.RedirctUri.Value, _hmrcVatSettings.RedirectUri);
            Assert.True(hmrcSettingsPage.ClientSecret.Value.IsNullOrEmpty());
            Assert.AreEqual(hmrcSettingsPage.HmrcApplicationName.Value, _hmrcVatSettings.HmrcApplicationName);

            hmrcSettingsPage.ClientSecret.Input("xxx");
            hmrcSettingsPage.ClientId.Input("xxx");
            hmrcSettingsPage.RedirctUri.Input("xxx");
            hmrcSettingsPage.HmrcApplicationName.Input("xxx");

            hmrcSettingsPage.SaveButton.Click();

            Assert.True(popups.FlashAlertIsDisplayed());
        }
    }
}
