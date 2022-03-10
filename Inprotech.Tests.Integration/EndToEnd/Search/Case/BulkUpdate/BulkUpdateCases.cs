using System;
using System.Linq;
using System.Threading;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Interactions;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.BulkUpdate
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class BulkUpdateCases : IntegrationTest
    {
        [TearDown]
        public void CleanupModifiedData()
        {
            DbSetup.Do(x =>
            {
                var shouldEnableRichTextFormatting = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.EnableRichTextFormatting);
                shouldEnableRichTextFormatting.BooleanValue = false;
                x.DbContext.SaveChanges();
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void BulkUpdateGetsDisabledOnSelectingClear(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkUpdatePageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys(Keys.Enter).Build().Perform();
            page.ResultsGrid.SelectRow(0);
            page.BulkOperationButton.Click();
            driver.WaitForAngular();
            Assert.AreNotEqual("disabled", page.BulkUpdate.GetAttribute("class"));

            page.ClearSelected.Click();
            driver.WaitForAngular();
            Assert.AreEqual("disabled", page.BulkUpdate.GetAttribute("class"));

            page.SelectThisPage.Click();
            driver.WaitForAngular();
            Assert.AreNotEqual("disabled", page.BulkUpdate.GetAttribute("class"));

            ReloadPage(driver);
            page.ResultsGrid.SelectRow(0);
            page.ResultsGrid.SelectRow(1);
            page.BulkOperationButton.Click();
            page.BulkUpdateButton.Click();
            Assert.AreEqual("Bulk Update", page.BulkUpdatePageTitle.Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void BulkUpdateFieldPageIsEditable(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkUpdatePageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys(Keys.Enter).Build().Perform();
            page.ResultsGrid.SelectRow(0);
            page.BulkOperationButton.Click();
            page.BulkUpdateButton.Click();
            var str1 = new[] {"Case Office", "Profit Centre", "Case Family", "Purchase Order", "Entity Size", "Type of Mark", "Title/Mark"};
            foreach (var t in str1) Assert.AreEqual(t, driver.FindElement(By.XPath("//label[text()='" + t + "']")).Text);
            var url = driver.WithJs().GetUrl();
            StringAssert.Contains("bulkupdate", url);
            driver.WaitForAngular();
            page.CaseOfficeInList.Click();
            page.NewOfficeText.Click();
            Assert.AreEqual("New Office", page.CaseOfficeTextField.GetAttribute("value"));

            page.CaseOfficeClearField.Click();
            Assert.AreNotEqual("New Office", page.CaseOfficeTextField.GetAttribute("value"));
            Assert.AreEqual("true", page.CaseOfficeTextField.GetAttribute("disabled"));

            page.CaseOfficeClearField.Click();
            Assert.AreEqual(null, page.CaseOfficeTextField.GetAttribute("disabled"));

            page.PurchaseOrderTextField.SendKeys("Test123");
            Assert.AreEqual("Test123", page.PurchaseOrderTextField.GetAttribute("value"));

            page.PurchaseOrderClearField.Click();
            Assert.AreEqual("true", page.PurchaseOrderTextField.GetAttribute("disabled"));

            page.PurchaseOrderClearField.Click();
            Assert.AreEqual(null, page.PurchaseOrderTextField.GetAttribute("disabled"));

            page.TitleMarkTextArea.SendKeys("Test123");
            Assert.AreEqual("Test123", page.TitleMarkTextArea.GetAttribute("value"));

            page.TitleMarkClearField.Click();
            Assert.AreEqual("true", page.TitleMarkTextArea.GetAttribute("disabled"));

            page.TitleMarkClearField.Click();
            Assert.AreEqual(null, page.TitleMarkTextArea.GetAttribute("disabled"));

            page.LargeEntityInDropdown.Click();
            page.EntitySizeClearField.Click();
            Assert.AreEqual("true", page.EntitySizeTextArea.GetAttribute("disabled"));

            page.EntitySizeClearField.Click();
            Assert.AreEqual(null, page.EntitySizeTextArea.GetAttribute("disabled"));

            page.CaseOfficeInList.Click();
            page.NewOfficeText.Click();
            Assert.AreEqual("New Office", page.CaseOfficeTextField.GetAttribute("value"));

            page.PurchaseOrderTextField.SendKeys("Test123");
            Assert.AreEqual("Test123", page.PurchaseOrderTextField.GetAttribute("value"));

            page.ClearButton.Click();
            Assert.AreEqual(null, page.CaseOfficeTextField.GetAttribute("disabled"));
            Assert.AreNotEqual("New Office", page.CaseOfficeTextField.GetAttribute("value"));
            Assert.AreEqual(null, page.PurchaseOrderTextField.GetAttribute("disabled"));
            Assert.AreNotEqual("Test123", page.PurchaseOrderTextField.GetAttribute("value"));

            page.BackButton.Click();
            driver.WaitForAngular();
            url = driver.WithJs().GetUrl();
            StringAssert.Contains("search-result", url);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void BulkUpdateFieldPageSaveFunctionality(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                new CaseBuilder(x.DbContext).Create("e2e_bu1");
                new CaseBuilder(x.DbContext).Create("e2e_bu2");
                x.DbContext.SaveChanges();
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkUpdatePageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys("e2e_bu").Build().Perform();
            driver.WaitForAngular();
            page.SearchButton.Click();
            page.ResultsGrid.SelectRow(0);
            page.ResultsGrid.SelectRow(1);
            page.BulkOperationButton.Click();
            page.BulkUpdateButton.Click();
            page.CaseOfficeInList.Click();
            page.NewOfficeText.Click();
            Assert.AreEqual("New Office", page.CaseOfficeTextField.GetAttribute("value"));

            page.LargeEntityInDropdown.Click();
            page.TitleMarkClearField.Click();
            page.ApplyButton.Click();
            Assert.IsTrue(page.ConfirmBulkUpdate.Displayed);
            Assert.AreEqual("New Office", page.FirstConfirmationValue.Text);
            Assert.AreEqual("Large Entity", page.SecondConfirmationValue.Text);
            StringAssert.Contains("Title/Mark", page.RemovedFieldConfirmation.Text);
            Assert.IsTrue(page.ReplacedFieldConfirmation.Displayed);

            page.ProceedButton.Click();
            page.BackButton.Click();
            driver.WaitForAngular();
            Thread.Sleep(20000);
            ReloadPage(driver);
            page.SecondRecord.Click();
            var page2 = new SummaryTopic(driver);
            StringAssert.Contains("New Office", page2.FieldValue("caseOffice"));
            StringAssert.Contains("Large Entity", page2.FieldValue("entitySize"));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AllowBulkUpdateOfCaseText(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var ct = x.DbContext.Set<Country>().FirstOrDefault(_ => _.Id == "AU");
                var pt = x.DbContext.Set<PropertyType>().FirstOrDefault(_ => _.Code == "T");
                var @case = new CaseBuilder(x.DbContext).Create("e2e_bu1", true, null, ct, pt);
                var caseText = new CaseText(@case.Id, KnownTextTypes.Description, 0, null) {Language = 4707, Text = "TESTING"};
                x.DbContext.Set<CaseText>().Add(caseText);
                x.DbContext.SaveChanges();
            });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkUpdatePageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys("e2e_bu1").Build().Perform();
            driver.WaitForAngular();
            page.SearchButton.Click();
            page.ResultsGrid.SelectRow(0);
            page.BulkOperationButton.Click();
            page.BulkUpdateButton.Click();
            page.TextTypeSelector.Click();
            page.DescriptionTextType.Click();
            page.LanguageSelector.Click();
            page.GermanLanguage.Click();
            page.NewTextArea.SendKeys("APPEND TO Description");
            var notificationCount = page.NotificationButton.Count == 0 ? 0 : page.NotificationTextCount;
            page.ApplyButton.Click();
            Assert.IsTrue(page.ConfirmBulkUpdate.Displayed);

            page.ProceedButton.Click();
            page.NotificationCount(notificationCount);
            page.NotificationButton.First().Click();
            page.LatestBulkUpdateLink.Click();
            driver.WaitForAngular();
            page.CaseLinkText.Click();
            Assert.IsTrue(page.LanguageText.Displayed);
            Assert.IsTrue(page.TypeText.Displayed);
            StringAssert.Contains("TESTING", page.AppendedTextRow.Text);
            StringAssert.Contains("APPEND TO Description", page.AppendedTextRow.Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AllowBulkUpdateOfGoodsAndServicesText(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var ct = x.DbContext.Set<Country>().FirstOrDefault(_ => _.Id == "AU");
                var pt = x.DbContext.Set<PropertyType>().FirstOrDefault(_ => _.Code == "T");
                var @case = new CaseBuilder(x.DbContext).Create("e2e_bu1", true, null, ct, pt);
                @case.LocalClasses = "02";
                var caseText = new CaseText(@case.Id, KnownTextTypes.GoodsServices, 1, "02") {ModifiedDate = DateTime.Now, Text = "TESTING"};
                x.DbContext.Set<CaseText>().Add(caseText);
                x.DbContext.SaveChanges();
            });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkUpdatePageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys("e2e_bu1").Build().Perform();
            driver.WaitForAngular();
            page.SearchButton.Click();
            page.ResultsGrid.SelectRow(0);
            page.BulkOperationButton.Click();
            page.BulkUpdateButton.Click();
            page.TextTypeSelector.Click();
            page.GoodsAndServicesTextType.Click();
            page.ClassSelector.Click();
            page.ClassTextType.Click();
            page.NewTextArea.SendKeys("Replace With This Text");
            var notificationCount = page.NotificationButton.Count == 0 ? 0 : page.NotificationTextCount;
            page.ApplyButton.Click();
            Assert.IsTrue(page.ConfirmBulkUpdate.Displayed);

            page.ProceedButton.Click();
            page.NotificationCount(notificationCount);
            page.NotificationButton.First().Click();
            page.LatestBulkUpdateLink.Click();
            driver.WaitForAngular();
            page.CaseLinkText.Click();
            Assert.IsTrue(page.ReplacedText.Displayed);
            StringAssert.DoesNotContain("TESTING", page.AppendedTextRow.Text);
            StringAssert.Contains("Replace With This Text", page.AppendedTextRow.Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AllowBulkUpdateOfFileLocation(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var ct = x.DbContext.Set<Country>().FirstOrDefault(_ => _.Id == "AU");
                var pt = x.DbContext.Set<PropertyType>().FirstOrDefault(_ => _.Code == "T");
                var @case = new CaseBuilder(x.DbContext).Create("e2e_bu1", true, null, ct, pt);
                @case.LocalClasses = "02";
                var caseText = new CaseText(@case.Id, KnownTextTypes.GoodsServices, 1, "02") {ModifiedDate = DateTime.Now, Text = "TESTING"};
                x.DbContext.Set<CaseText>().Add(caseText);
                x.DbContext.SaveChanges();
            });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkUpdatePageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys("e2e_bu1").Build().Perform();
            driver.WaitForAngular();
            page.SearchButton.Click();
            page.ResultsGrid.SelectRow(0);
            page.BulkOperationButton.Click();
            page.BulkUpdateButton.Click();
            page.FileLocationSelector.Click();
            page.RecordsManagementFileLocation.Click();
            page.MovedBy.OpenPickList();
            page.MovedBy.ModalSearchButton().ClickWithTimeout();
            page.MovedByText.Click();
            page.BayNumberInputField.SendKeys("11111111112222222222");
            var notificationCount = page.NotificationButton.Count == 0 ? 0 : page.NotificationTextCount;
            page.ApplyButton.Click();
            Assert.IsTrue(page.ConfirmBulkUpdate.Displayed);

            page.ProceedButton.Click();
            page.NotificationCount(notificationCount);
            page.NotificationButton.First().Click();
            page.LatestBulkUpdateLink.Click();
            page.CaseLinkText.Click();
            StringAssert.Contains("Records Management", page.FileLocationInCaseSearch.Text);

            page.SearchButton.Click();
            page.ResultsGrid.SelectRow(0);
            page.BulkOperationButton.Click();
            page.BulkUpdateButton.Click();
            page.FileLocationSelector.Click();
            page.RecordsManagementFileLocation.Click();
            page.FileLocationUpdateRemoveButton.Click();
            page.ApplyButton.Click();
            Assert.IsTrue(page.ConfirmBulkUpdate.Displayed);

            page.ProceedButton.Click();
            Thread.Sleep(30000);
            page.NotificationButton.First().Click();
            page.LatestBulkUpdateLink.Click();
            driver.WaitForAngular();
            page.CaseLinkText.Click();
            StringAssert.DoesNotContain("Records Management", page.FileLocationInCaseSearch.Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void EditStatusOfListOfSelectedCases(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var ct = x.DbContext.Set<Country>().FirstOrDefault(_ => _.Id == "AU");
                var pt = x.DbContext.Set<PropertyType>().FirstOrDefault(_ => _.Code == "T");
                new CaseBuilder(x.DbContext).Create("e2e_bu1", true, null, ct, pt);
                var statusCertificateReceived = x.DbContext.Set<Status>().FirstOrDefault(_ => _.Id == -219);
                if (statusCertificateReceived != null) statusCertificateReceived.ConfirmationRequiredFlag = 0;
                x.DbContext.SaveChanges();
            });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkUpdatePageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys("e2e_bu1").Build().Perform();
            driver.WaitForAngular();
            page.SearchButton.Click();
            page.ResultsGrid.SelectRow(0);
            page.BulkOperationButton.Click();
            page.BulkUpdateButton.Click();
            page.CaseStatusSelector.Click();
            page.CertificateReceivedStatus.Click();
            var notificationCount = page.NotificationButton.Count == 0 ? 0 : page.NotificationTextCount;
            page.ApplyButton.Click();
            Assert.IsTrue(page.ConfirmBulkUpdate.Displayed);

            page.ProceedButton.Click();
            page.NotificationCount(notificationCount);
            page.NotificationButton.First().Click();
            page.LatestBulkUpdateLink.Click();
            page.CaseLinkText.Click();
            foreach (var val in page.CaseStatus) StringAssert.Contains("Certificate received", val.Text);
            page.SearchButton.Click();
            page.ResultsGrid.SelectRow(0);
            page.BulkOperationButton.Click();
            page.BulkUpdateButton.Click();
            page.RemoveStatusCheckbox.Click();
            page.ApplyButton.Click();
            Assert.IsTrue(page.ConfirmBulkUpdate.Displayed);

            page.ProceedButton.Click();
            Thread.Sleep(30000);
            page.NotificationButton.First().Click();
            page.LatestBulkUpdateLink.Click();
            driver.WaitForAngular();
            page.CaseLinkText.Click();
            foreach (var val in page.CaseStatus) StringAssert.DoesNotContain("Certificate received", val.Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AbilityToRequestPasswordConfirmationToChangeTheStatus(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var ct = x.DbContext.Set<Country>().FirstOrDefault(_ => _.Id == "AU");
                var pt = x.DbContext.Set<PropertyType>().FirstOrDefault(_ => _.Code == "T");
                new CaseBuilder(x.DbContext).Create("e2e_bu1", true, null, ct, pt);
                var statusCertificateReceived = x.DbContext.Set<Status>().FirstOrDefault(_ => _.Id == -219);
                if (statusCertificateReceived != null) statusCertificateReceived.ConfirmationRequiredFlag = 1;
                x.DbContext.SaveChanges();
            });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkUpdatePageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys("e2e_bu1").Build().Perform();
            driver.WaitForAngular();
            page.SearchButton.Click();
            page.ResultsGrid.SelectRow(0);
            page.BulkOperationButton.Click();
            page.BulkUpdateButton.Click();
            page.CaseStatusSelector.Click();
            page.CertificateReceivedStatus.Click();
            StringAssert.Contains("Confirm Password", page.ConfirmPasswordDialog.Text);
            Assert.IsTrue(page.ConfirmationText.Displayed);

            page.CancelButton.Click();
            StringAssert.Contains(string.Empty, page.CaseStatusValue.GetAttribute("data-search-value"));

            page.CaseStatusSelector.Click();
            page.CertificateReceivedStatus.Click();
            page.PasswordField.SendKeys("Your Password");
            page.ConfirmButton.Click();
            StringAssert.Contains("Certificate received", page.CaseStatusValue.GetAttribute("data-search-value"));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void BulkUpdateFieldPageIsEditableWhenEnableRichTextFormatting(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var shouldEnableRichTextFormatting = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.EnableRichTextFormatting);
                shouldEnableRichTextFormatting.BooleanValue = true;
                var ct = x.DbContext.Set<Country>().FirstOrDefault(_ => _.Id == "AU");
                var pt = x.DbContext.Set<PropertyType>().FirstOrDefault(_ => _.Code == "T");
                var @case = new CaseBuilder(x.DbContext).Create("e2e_bu1", true, null, ct, pt);
                var caseText = new CaseText(@case.Id, KnownTextTypes.Description, 0, null) {Language = 4707, Text = "TESTING"};
                x.DbContext.Set<CaseText>().Add(caseText);
                x.DbContext.SaveChanges();
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BulkUpdatePageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys("e2e_bu1").Build().Perform();
            driver.WaitForAngular();
            page.SearchButton.Click();
            page.ResultsGrid.SelectRow(0);
            page.BulkOperationButton.Click();
            page.BulkUpdateButton.Click();
            page.LanguageSelector.Click();
            page.GermanLanguage.Click();
            page.TextTypeSelector.Click();
            page.DescriptionTextType.Click();
            Assert.AreEqual("Please enter text here", page.RichTextArea.GetAttribute("data-placeholder"));

            driver.WaitForAngularWithTimeout(2000);
            driver.ExecuteScript("document.querySelectorAll('.ql-editor')[0].textContent='APPEND TO Description'");
            var notificationCount = page.NotificationButton.Count == 0 ? 0 : page.NotificationTextCount;
            page.ApplyButton.Click();
            Assert.IsTrue(page.ConfirmBulkUpdate.Displayed);
            Assert.AreEqual("Please enter text here", page.RichTextArea.GetAttribute("data-placeholder"));

            page.ProceedButton.Click();
            page.NotificationCount(notificationCount);
            page.NotificationButton.First().Click();
            page.LatestBulkUpdateLink.Click();
            driver.WaitForAngular();
            page.CaseLinkText.Click();
            Assert.IsTrue(page.LanguageText.Displayed);
            Assert.IsTrue(page.TypeText.Displayed);
            StringAssert.Contains("TESTING", page.AppendedRichTextRow.Text);
            StringAssert.Contains("APPEND TO Description", page.AppendedRichTextRow.Text);
        }
    }
}