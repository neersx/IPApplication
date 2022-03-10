using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.ScreenDesigner.Cases
{
    class CaseScreenDesignerMaintenancePage : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShouldDisplayAppropriateCriteriaDetails(BrowserType browserType)
        {
           
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainCpassRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithPermission(ApplicationTask.MaintainRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .Create();
            var data = DbSetup.Do(setup =>
                                      {
                                          var child = setup.InsertWithNewId(new Criteria
                                          {
                                              Description = Fixture.Prefix("child"),
                                              PurposeCode = CriteriaPurposeCodes.WindowControl,
                                              UserDefinedRule = 0,
                                              Office = new Office(Fixture.Integer(), Fixture.String(10)),
                                              //CaseType = new CaseType(Fixture.String(1), Fixture.String(10)),
                                              //Country = new Country(Fixture.String(2), Fixture.String(10), Fixture.String(2)),
                                              //PropertyType = new PropertyType(Fixture.String(1), Fixture.String(10)),
                                              //SubType = new SubType(Fixture.String(2), Fixture.String(10)),
                                              //Basis = new ApplicationBasis(Fixture.String(2), Fixture.String(10))
                                          });

                                          var parent = setup.InsertWithNewId(new Criteria
                                          {
                                              Description = Fixture.Prefix("parent"),
                                              PurposeCode = CriteriaPurposeCodes.WindowControl,
                                              UserDefinedRule = 1,
                                              Office = new Office(Fixture.Integer(), Fixture.String(10)),
                                              //CaseType = new CaseType(Fixture.String(1), Fixture.String(10)),
                                              //Country = new Country(Fixture.String(2), Fixture.String(10), Fixture.String(2)),
                                              //PropertyType = new PropertyType(Fixture.String(1), Fixture.String(10)),
                                              //SubType = new SubType(Fixture.String(2), Fixture.String(10)),
                                              //Basis = new ApplicationBasis(Fixture.String(2), Fixture.String(10))
                                          });

                                          setup.Insert(new Inherits
                                          {
                                              Criteria = child,
                                              FromCriteria = parent
                                          });

                                          return new
                                          {
                                              Child = child,
                                              Parent = parent
                                          };
                                      });

            SignIn(driver, $"/#/configuration/rules/screen-designer/cases/{data.Child.Id}");

            var page = new CaseScreenDesignerMaintenancePageObject(driver);

            Assert.IsFalse(page.IsSaveDisplayed, "save button is not displayed");
            AssertCriteria(page, data.Child, driver);

            SignIn(driver, $"/#/configuration/rules/screen-designer/cases/{data.Parent.Id}");
            
            AssertCriteria(page, data.Parent, driver);

        }

        void AssertCriteria(CaseScreenDesignerMaintenancePageObject page, Criteria criteria, NgWebDriver driver)
        {
            driver.WaitForAngular();
            Assert.AreEqual(page.Office, criteria.Office.Name ?? string.Empty);
            //Assert.AreEqual(page.Program ?? "", criteria.ProgramId.Name ?? string.Empty);
            Assert.AreEqual(page.CaseType, criteria.CaseType?.Name ?? string.Empty);
            Assert.AreEqual(page.Jurisdiction, criteria.Country?.Name ?? string.Empty);
            Assert.AreEqual(page.PropertyType, criteria.PropertyType?.Name ?? string.Empty);
            Assert.AreEqual(page.CaseCategory, criteria.CaseCategory?.Name ?? string.Empty);
            Assert.AreEqual(page.SubType, criteria.SubType?.Name ?? string.Empty);
            Assert.AreEqual(page.Basis, criteria.Basis?.Name ?? string.Empty);
            //Assert.AreEqual(page.Profile, criteria.Profile?.Name);
        }
    }
}
