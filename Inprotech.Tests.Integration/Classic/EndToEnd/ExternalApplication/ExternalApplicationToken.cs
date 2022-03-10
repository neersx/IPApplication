using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.ExternalApplication
{
    [TestFixture]
    [Category(Categories.E2E)]
    [RebuildsIntegrationDatabase]
    public class ExternalApplicationToken : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void GenerateTokenThenSetExpiry(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/integration/externalapplication");

            var popups = new CommonPopups(driver);
            var app = GetFirst();
            var tokenOriginal = app.Token;

            driver.FindElement(By.Id($"btnGenerateToken_{app.Id}")).ClickWithTimeout();

            popups.WaitForFlashAlert();

            driver.Wait().ForVisible(By.Id($"btnEdit_{app.Id}"));

            var updated = GetFirst().Token;

            Assert.AreNotEqual(tokenOriginal, updated);

            driver.FindElement(By.Id($"btnEdit_{app.Id}")).Click();

            driver.With<EditApplicationLinkPageObject>(page =>
            {
                page.ExpiryDate.Clear();
                page.ExpiryDate.SendKeys("18 Dec 2025");
                page.Apply();
                popups.WaitForFlashAlert();
            });

            var updatedExpiryDate = GetFirst().ExpiryDate.ToString("dd-MMM-yyyy");

            Assert.AreEqual("18-Dec-2025", updatedExpiryDate);
        }

        static dynamic GetFirst()
        {
            return IntegrationDbSetup.Do(x =>
                                         {
                                             return x.IntegrationDbContext
                                                     .Set<Inprotech.Integration.ExternalApplications.ExternalApplication>().OrderBy(s => s.Name)
                                                     .Select(_ => new
                                                     {
                                                         _.Id,
                                                         _.ExternalApplicationToken.Token,
                                                         ExpiryDate = _.ExternalApplicationToken.ExpiryDate ?? DateTime.MinValue
                                                     }).First();
                                         });
        }

        public class EditApplicationLinkPageObject : MaintenanceModal
        {
            public EditApplicationLinkPageObject(NgWebDriver driver) : base(driver, null)
            {
            }

            public NgWebElement ExpiryDate => Driver.FindElement(By.ClassName("datepicker-input"));

            public IpTextField CertificateName => new IpTextField(Driver).ByName("name");

            public IpTextField Password => new IpTextField(Driver).ByName("password");
            public IpTextField CustomerNumbers => new IpTextField(Driver).ByName("clientNumbers");
        }
    }
}