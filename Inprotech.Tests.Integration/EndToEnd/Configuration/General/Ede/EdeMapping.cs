using System;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Ede
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class EdeMapping : IntegrationTest
    {
        public enum EdeType
        {
            File,
            IpOneData,
            UsptoPrivatePair,
            UsptoTsdr
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void Item(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            foreach (EdeType type in Enum.GetValues(typeof(EdeType)))
            {
                SignIn(driver, "/#/configuration/general/ede/datamapping/" + type);

                var pageDetails = new EdeMappingDetailPage(driver);

                #region verify page fields
                pageDetails.DocumentsTopic.NavigateTo();
                driver.FindElement(By.XPath("//div[@data-topic-key='Events']//button[@ng-click='vm.add()']//span[contains(@class,'cpa-icon cpa-icon-plus-circle')]")).Click();
                Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.DescriptionTextBox(driver).GetAttribute("value"), "Ensure Descripiton exists");
                Assert.IsNull(pageDetails.DefaultsTopic.DescriptionTextBox(driver).GetAttribute("disabled"), "Ensure Descripiton is enabled");
                Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.EventPickList.GetText(), "Ensure Data Item Picklist is empty");
                Assert.AreEqual(true, pageDetails.DefaultsTopic.EventPickList.Enabled, "Ensure Data Item Picklist is enabled");
                Assert.AreEqual(false, pageDetails.DefaultsTopic.IgnoreCheckbox.IsDisabled, "Ensure Ignore checkbox is enabled");
                Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
                Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
                #endregion

                #region Validate
                var popups = new CommonPopups(driver);
                pageDetails.DefaultsTopic.DescriptionTextBox(driver).SendKeys("12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789");
                Assert.IsTrue(new TextField(driver, "description").HasError, "Description should be maximum 254 characters");
                pageDetails.DefaultsTopic.DescriptionTextBox(driver).Clear();
                pageDetails.DefaultsTopic.DescriptionTextBox(driver).SendKeys("e2e");
                pageDetails.SaveButton.ClickWithTimeout();
                Assert.IsNotNull(popups.AlertModal, "Alert modal is present");
                popups.AlertModal.Ok();
                #endregion

                #region Add Data Mapping
                pageDetails.DefaultsTopic.IgnoreCheckbox.Click();
                driver.WaitForAngular();
                pageDetails.SaveButton.ClickWithTimeout();
                Assert.AreEqual("e2e", driver.FindElement(By.XPath("//div[@class='kendo-search-grid-placeholder']//tr//td[contains(.,'e2e')]")).Text, "Description is same");
                #endregion

                #region Edit Data Mapping
                driver.FindElement(By.XPath("//div[@class='kendo-search-grid-placeholder']//tr//td[contains(.,'e2e')]//parent::*//td//ip-checkbox//input[@type='checkbox']")).WithJs().Click();
                driver.FindElement(By.XPath("//div[@data-context='Events']//span[@name='list-ul']")).Click();
                pageDetails.DefaultsTopic.ClickOnEdit(driver);
                driver.WaitForAngularWithTimeout();
                pageDetails.DefaultsTopic.DescriptionTextBox(driver).Clear();
                pageDetails.DefaultsTopic.DescriptionTextBox(driver).SendKeys("e2e-edit");
                pageDetails.SaveButton.ClickWithTimeout();
                pageDetails.DiscardButton.ClickWithTimeout();
                Assert.AreEqual("e2e-edit", driver.FindElement(By.XPath("//div[@class='kendo-search-grid-placeholder']//tr//td[contains(.,'e2e-edit')]")).Text, "Ensure value is same");
                #endregion

                #region Delete Data Mapping
                driver.FindElement(By.XPath("//div[@class='kendo-search-grid-placeholder']//tr//td[contains(.,'e2e-edit')]//parent::*//td//ip-checkbox//input[@type='checkbox']")).WithJs().Click();
                driver.FindElement(By.XPath("//div[@data-context='Events']//span[@name='list-ul']")).Click();
                pageDetails.DefaultsTopic.ClickOnDelete(driver);
                popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
                Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.XPath("//div[@class='kendo-search-grid-placeholder']//tr//td[contains(.,'e2e-edit')]")));
                #endregion
            }
        }
    }
}
