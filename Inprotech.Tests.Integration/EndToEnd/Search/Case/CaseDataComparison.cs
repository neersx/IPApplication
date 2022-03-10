using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseDataComparison : IntegrationTest
    {
        TestUser _loginUser;

        [SetUp]
        public void CreateAdminUser()
        {
            _loginUser = new Users()
                         .WithPermission(ApplicationTask.ViewCaseDataComparison)
                         .Create();
        }

        static dynamic GetCasesData()
        {
            var data = DbSetup.Do(setup =>
            {
                var casePrefix = Fixture.AlphaNumericString(3);
                var case1 = new CaseBuilder(setup.DbContext).Create(casePrefix + "1");
                var case2 = new CaseBuilder(setup.DbContext).Create(casePrefix + "2");
                return new
                {
                    CasePrefix = casePrefix,
                    CaseIrns = new[] {case1.Irn, case2.Irn}
                };
            });
            return data;
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void Run(BrowserType browserType)
        {
            var data = GetCasesData();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/search-result?queryContext=2&q={data.CasePrefix}");

            var grid = new AngularKendoGrid(driver, "searchResults", "a123");
            grid.ActionMenu.OpenOrClose();
            Assert.IsTrue(grid.ActionMenu.Option("case-data-comparison").Disabled(), "Expected case data comparison option to be disabled when none selected");
            grid.SelectRow(1);
            grid.ActionMenu.OpenOrClose();
            Assert.IsTrue(grid.ActionMenu.Option("case-data-comparison").Enabled, "Expected case data comparison option to be enabled when one or more selected");
            grid.ActionMenu.Option("case-data-comparison").WithJs().Click();

            driver.Wait().ForTrue(() => driver.WindowHandles.Count >1);
            var element = driver.SwitchTo().Window(driver.WindowHandles[1]).FindElement(By.XPath("//h2/span[2]"));
            Assert.AreEqual("Case Data Comparison Inbox", element.Text);
        }
    }
}
