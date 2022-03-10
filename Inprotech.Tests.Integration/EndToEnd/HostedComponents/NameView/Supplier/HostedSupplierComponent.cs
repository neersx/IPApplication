using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.Actions;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Names;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.DataValidation;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.NameView.Supplier
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedSupplierComponent : IntegrationTest
    {
        [TearDown]
        public void TearDown()
        {
            DbSetup.Do(db =>
            {
                foreach (var dataValidation in DataValidations)
                {
                    db.DbContext.Set<DataValidation>().Single(_ => _.Id == dataValidation.Id).InUseFlag = true;
                }
                db.DbContext.SaveChanges();
            });
        }

        List<DataValidation> DataValidations { get; set; }

        public void TurnOffDataValidations()
        {
            DbSetup.Do(db =>
            {
                DataValidations = db.DbContext.Set<DataValidation>().Where(_ => _.InUseFlag && _.FunctionalArea == "N").ToList();
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
        public void TestHostedSupplierComponentLifecycle(BrowserType browserType)
        {
            var setup = new NamesDataSetup();
            var data = setup.CreateNamesScreenDataSetup();
            TurnOffDataValidations();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test");
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Name View Supplier";
            driver.WaitForAngular();

            page.NamePicklist.SelectItem(data.Supplier.LastName);
            driver.WaitForAngular();

            page.NameSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var supplier = new SupplierDetailsTopic(driver);
                Assert.True(supplier.SupplierType.IsDisplayed, "Supplier Type dropdown should be displayed in topic");
                Assert.AreEqual(data.Creditor.PurchaseDescription, supplier.PurchaseDescriptionTextbox.Value(), "The purchase description should be correct");
                Assert.True(supplier.Revert.Displayed, "Ensure that the revert button is displayed");
                driver.WaitForAngular();
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedSupplierComponentSaveAndSanityCheck(BrowserType browserType)
        {
            var setup = new NamesDataSetup();
            var data = setup.CreateNamesScreenDataSetup();
            TurnOffDataValidations();
            var dv = new DataValidation();
            DbSetup.Do(db =>
            {
                dv.InUseFlag = true;
                dv.FunctionalArea = "N";
                dv.DisplayMessage = "there is a sanity problem";
                dv.RuleDescription = "sanity problem";
                dv.Notes = "a sanity problem has been found";
                dv.IsWarning = false;
                db.DbContext.Set<DataValidation>().Add(dv);
                db.DbContext.SaveChanges();
            });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test");
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Name View Supplier";
            driver.WaitForAngular();

            page.NamePicklist.SelectItem(data.Supplier.LastName);
            driver.WaitForAngular();

            page.NameSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var supplier = new SupplierDetailsTopic(driver);
                driver.WaitForAngular();
                supplier.PurchaseDescriptionTextbox.SendKeys("test e2e");
                Assert.False(supplier.SaveButton.IsDisabled());
                supplier.SaveButton.Click();
                driver.WaitForAngular();
            });

            page.WaitForLifeCycleAction("SanityCheckResults");
            var sanityCheckResult = page.LifeCycleMessages.Last();
            var payload = sanityCheckResult.Payload.ToObject<HostedTestPageObject.SanityCheckPayload[]>();
            Assert.AreEqual("there is a sanity problem", payload[0].DisplayMessage, "Sanity check results are returned");
            driver.DoWithinFrame(() =>
            {
                var supplier = new SupplierDetailsTopic(driver);
                Assert.False(supplier.SaveButton.IsDisabled(), "Saved is blocked");
            });
        }
    }
}
