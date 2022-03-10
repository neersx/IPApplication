using Inprotech.Tests.Integration.EndToEnd.Portfolio.Names;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.NameView.TrustAccounting
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedSupplierComponent : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedSupplierComponentLifecycle(BrowserType browserType)
        {
            var setup = new NamesDataSetup();
            var data = setup.CreateNamesScreenDataSetup();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test");
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Name View Trust Accounting";
            driver.WaitForAngular();

            page.NamePicklist.SelectItem(data.Supplier.LastName);
            driver.WaitForAngular();

            page.NameSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var hostedTrustTopic = new TrustAccountingTopic(driver);
                Assert.AreEqual(2, hostedTrustTopic.Grid.Rows.Count, "Hosted TrustAccounting grid contains 2 records");
                driver.WaitForAngular();
            });
        }
    }
}
