using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case
{
    
    [Category(Categories.E2E)]
    [TestFixture]
    public class ExportToCpaXml : IntegrationTest
    {
        TestUser _loginUser;

        [SetUp]
        public void CreateAdminUser()
        {
            _loginUser = new Users()
                         .WithPermission(ApplicationTask.AdvancedCaseSearch)
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
        public void Export(BrowserType browserType)
        {
            var data = GetCasesData();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/search-result?queryContext=2&q={data.CasePrefix}");

            var grid = new AngularKendoGrid(driver, "searchResults", "a123");
            grid.ActionMenu.OpenOrClose();
            Assert.IsTrue(grid.ActionMenu.Option("case-cpa-xml-import").Enabled, "Expected Export All to CPA-XML option to be enabled when none selected");
            grid.ActionMenu.Option("case-cpa-xml-import").WithJs().Click();
            grid.SelectRow(1);
            grid.ActionMenu.OpenOrClose();
            Assert.IsTrue(grid.ActionMenu.Option("case-cpa-xml-import").Enabled, "Expected Export to CPA-XML option to be enabled when one or more selected");
            grid.ActionMenu.Option("case-cpa-xml-import").WithJs().Click();
        }
    }
}
