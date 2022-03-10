using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.ScreenDesigner.Cases
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseScreenDesignerSearch : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShouldShowResults(BrowserType browserType)
        {
            var data = new CaseScreenDesignerDbSetup().SetUp();
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainCpassRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithPermission(ApplicationTask.MaintainRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .Create();
            SignIn(driver, "/#/configuration/rules/screen-designer/cases", user.Username, user.Password);
            driver.WaitForAngularWithTimeout();
            var page = new CaseScreenDesignerSearchPageObject(driver);

            page.SubmitButton.WithJs().Click();
            Assert.True(page.PageIsShown, "Page is shown");
            Assert.True(page.Grid.Rows.Any(), "Records are shown after search");
            page.Characteristics.Office.EnterAndSelect(data.Office.Name);
            page.CriteriaNotInUse.Click();

            page.SubmitButton.WithJs().Click();
            driver.WaitForAngular();

            Assert.AreEqual(3, page.Grid.Rows.Count, "3 matching rows are shown");
            page.CriteriaNotInUse.Click();

            page.SubmitButton.WithJs().Click();
            driver.WaitForAngular();
            Assert.AreEqual(2, page.Grid.Rows.Count, "2 matching rows are shown");

            page.Characteristics.Program.EnterAndSelect(data.Program.Name);
            page.SubmitButton.WithJs().Click();
            driver.WaitForAngular();
            Assert.AreEqual(1, page.Grid.Rows.Count, "1 matching row is shown");

            page.Characteristics.CaseType.EnterAndSelect(data.CaseType.Name);
            page.SubmitButton.WithJs().Click();
            driver.WaitForAngular();
            Assert.AreEqual(0, page.Grid.Rows.Count, "0 matching rows are shown");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShouldClearEntriesOnClearButtonPressed(BrowserType browserType)
        {
            var data = new CaseScreenDesignerDbSetup().SetUp();
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainCpassRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithPermission(ApplicationTask.MaintainRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .Create();
            SignIn(driver, "/#/configuration/rules/screen-designer/cases", user.Username, user.Password);
            driver.WaitForAngularWithTimeout();

            var page = new CaseScreenDesignerSearchPageObject(driver);

            page.Characteristics.Office.EnterAndSelect(data.Office.Name);
            page.SubmitButton.WithJs().Click();
            driver.WaitForAngularWithTimeout();

            CollectionAssert.IsNotEmpty(page.Grid.Rows, "Records are shown");
            Assert.True(page.ProtectedCriteria.IsChecked, "Protected Criteria checkbox checked by default");
            page.ProtectedCriteria.Click();
            Assert.False(page.ProtectedCriteria.IsChecked, "Protected Criteria checkbox is unchecked on click");
            page.Characteristics.Program.EnterAndSelect(data.Program.Name);
            driver.WaitForAngularWithTimeout();

            Assert.False(page.Characteristics.CaseCategory.Enabled, "Case category is disabled because case type isn't set");
            page.Characteristics.CaseType.EnterAndSelect(data.CaseType.Code);
            driver.WaitForAngularWithTimeout();
            Assert.True(page.Characteristics.CaseCategory.Enabled, "Case category is enabled because case type is set");
            page.Characteristics.Jurisdiction.EnterAndSelect(data.Jurisdiction.Name);
            page.Characteristics.PropertyType.EnterAndSelect(data.PropertyType.Name);
            page.Characteristics.CaseCategory.EnterAndSelect(data.CaseCategory.Name);

            page.Characteristics.SubType.EnterAndSelect(data.SubType.Name);

            page.Characteristics.Basis.EnterAndSelect(data.Basis.Code);
            page.Characteristics.Profile.EnterAndSelect(data.Profile.Name);
            driver.WaitForAngularWithTimeout();

            Assert.IsNotEmpty(page.Characteristics.Office.InputValue, "Office has value");
            Assert.IsNotEmpty(page.Characteristics.Program.InputValue, "Program has value");
            Assert.IsNotEmpty(page.Characteristics.CaseType.InputValue, "Case type has value");
            Assert.IsNotEmpty(page.Characteristics.Jurisdiction.InputValue, "Jurisdiction has value");
            Assert.IsNotEmpty(page.Characteristics.PropertyType.InputValue, "Property Type has value");
            Assert.IsNotEmpty(page.Characteristics.CaseCategory.InputValue, "Case category has value");
            Assert.IsNotEmpty(page.Characteristics.SubType.InputValue, "Sub type has value");
            Assert.IsNotEmpty(page.Characteristics.Basis.InputValue, "Basis has value");
            Assert.IsNotEmpty(page.Characteristics.Profile.InputValue, "Profile has value");

            page.ResetButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();

            Assert.True(string.IsNullOrWhiteSpace(page.Characteristics.Office.InputValue), "Office empty after clear button clicked");
            Assert.True(string.IsNullOrWhiteSpace(page.Characteristics.Program.InputValue), "InputValue empty after clear button clicked");
            Assert.True(string.IsNullOrWhiteSpace(page.Characteristics.CaseType.InputValue), "Case Type empty after clear button clicked");
            Assert.True(string.IsNullOrWhiteSpace(page.Characteristics.Jurisdiction.InputValue), "Jurisdiction empty after clear button clicked");
            Assert.True(string.IsNullOrWhiteSpace(page.Characteristics.PropertyType.InputValue), "Property Type empty after clear button clicked");
            Assert.True(string.IsNullOrWhiteSpace(page.Characteristics.CaseCategory.InputValue), "Case Category empty after clear button clicked");
            Assert.True(string.IsNullOrWhiteSpace(page.Characteristics.SubType.InputValue), "Sub type empty after clear button clicked");
            Assert.True(string.IsNullOrWhiteSpace(page.Characteristics.Basis.InputValue), "Basis empty after clear button clicked");
            Assert.True(string.IsNullOrWhiteSpace(page.Characteristics.Profile.InputValue), "Profile empty after clear button clicked");
            Assert.False(page.Characteristics.CaseCategory.Enabled, "Case category is disabled because case type isn't set");
            Assert.True(page.ProtectedCriteria.IsChecked, "Protected criteria is defaulted to checked");
            Assert.IsEmpty(page.Grid.Rows, "Grid is empty");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShouldMaintainTabSelectionsOnChangingTabs(BrowserType browserType)
        {
            var data = new CaseScreenDesignerDbSetup().SetUp();
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainCpassRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithPermission(ApplicationTask.MaintainRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .Create();
            SignIn(driver, "/#/configuration/rules/screen-designer/cases", user.Username, user.Password);
            driver.WaitForAngularWithTimeout();

            var page = new CaseScreenDesignerSearchPageObject(driver);

            page.Characteristics.Office.EnterAndSelect(data.Office.Name);
            page.SubmitButton.WithJs().Click();
            CollectionAssert.IsNotEmpty(page.Grid.Rows, "Records are shown");
            Assert.True(page.ProtectedCriteria.IsChecked, "Protected Criteria checkbox checked by default");
            page.ProtectedCriteria.Click();
            Assert.False(page.ProtectedCriteria.IsChecked, "Protected Criteria checkbox is unchecked on click");
            page.Characteristics.Program.EnterAndSelect(data.Program.Name);
            driver.WaitForAngularWithTimeout();

            Assert.False(page.Characteristics.CaseCategory.Enabled, "Case category is disabled because case type isn't set");
            page.Characteristics.CaseType.EnterAndSelect(data.CaseType.Code);
            driver.WaitForAngularWithTimeout();
            Assert.True(page.Characteristics.CaseCategory.Enabled, "Case category is enabled because case type is set");
            page.Characteristics.Jurisdiction.EnterAndSelect(data.Jurisdiction.Name);
            page.Characteristics.PropertyType.EnterAndSelect(data.PropertyType.Name);
            page.Characteristics.CaseCategory.EnterAndSelect(data.CaseCategory.Name);

            page.Characteristics.SubType.EnterAndSelect(data.SubType.Name);

            page.Characteristics.Basis.EnterAndSelect(data.Basis.Code);
            page.Characteristics.Profile.EnterAndSelect(data.Profile.Name);

            Assert.IsNotEmpty(page.Characteristics.Office.InputValue, "Office has value");
            Assert.IsNotEmpty(page.Characteristics.Program.InputValue, "Program has value");
            Assert.IsNotEmpty(page.Characteristics.CaseType.InputValue, "Case type has value");
            Assert.IsNotEmpty(page.Characteristics.Jurisdiction.InputValue, "Jurisdiction has value");
            Assert.IsNotEmpty(page.Characteristics.PropertyType.InputValue, "Property Type has value");
            Assert.IsNotEmpty(page.Characteristics.CaseCategory.InputValue, "Case category has value");
            Assert.IsNotEmpty(page.Characteristics.SubType.InputValue, "Sub type has value");
            Assert.IsNotEmpty(page.Characteristics.Basis.InputValue, "Basis has value");
            Assert.IsNotEmpty(page.Characteristics.Profile.InputValue, "Profile has value");

            page.CriteriaRadioButton.Click();
            driver.WaitForAngular();

            page.Criteria.EnterAndSelect(data.Criteria[0].Id.ToString());

            page.CharacteristicsRadioButton.Click();
            driver.WaitForAngular();

            Assert.IsNotEmpty(page.Characteristics.Office.InputValue, "Office has value");
            Assert.IsNotEmpty(page.Characteristics.Program.InputValue, "Program has value");
            Assert.IsNotEmpty(page.Characteristics.CaseType.InputValue, "Case type has value");
            Assert.IsNotEmpty(page.Characteristics.Jurisdiction.InputValue, "Jurisdiction has value");
            Assert.IsNotEmpty(page.Characteristics.PropertyType.InputValue, "Property Type has value");
            Assert.IsNotEmpty(page.Characteristics.CaseCategory.InputValue, "Case category has value");
            Assert.IsNotEmpty(page.Characteristics.SubType.InputValue, "Sub type has value");
            Assert.IsNotEmpty(page.Characteristics.Basis.InputValue, "Basis has value");
            Assert.IsNotEmpty(page.Characteristics.Profile.InputValue, "Profile has value");

            page.CriteriaRadioButton.Click();
            driver.WaitForAngular();
            Assert.AreNotEqual(0, page.Criteria.Tags.Count(), "Criteria has value");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CaseSearchSelectsAppropriateCriteriaValuesAndSearchesSuccessfully(BrowserType browserType)
        {
            var data = new CaseScreenDesignerDbSetup().SetUp();
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainCpassRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithPermission(ApplicationTask.MaintainRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .Create();
            SignIn(driver, "/#/configuration/rules/screen-designer/cases", user.Username, user.Password);
            driver.WaitForAngularWithTimeout();

            var page = new CaseScreenDesignerSearchPageObject(driver);
            page.CaseRadioButton.Click();

            driver.WaitForAngular();

            Assert.IsEmpty(page.Cases.Office.InputValue, "Office has no value");
            Assert.IsEmpty(page.Cases.Program.InputValue, "Program has no value");
            Assert.IsEmpty(page.Cases.CaseType.InputValue, "Case type has no value");
            Assert.IsEmpty(page.Cases.Jurisdiction.InputValue, "Jurisdiction has no value");
            Assert.IsEmpty(page.Cases.PropertyType.InputValue, "Property Type has no value");
            Assert.IsEmpty(page.Cases.CaseCategory.InputValue, "Case category has no value");
            Assert.IsEmpty(page.Cases.SubType.InputValue, "Sub type has no value");
            Assert.IsEmpty(page.Cases.Basis.InputValue, "Basis has no value");
            Assert.IsEmpty(page.Cases.Profile.InputValue, "Profile has no value");

            page.Case.EnterAndSelect(data.Case.Irn);
            driver.WaitForAngular();

            Assert.IsNotEmpty(page.Cases.Office.InputValue, "Office has value");
            Assert.IsNotEmpty(page.Cases.Program.InputValue, "Program has value");
            Assert.IsNotEmpty(page.Cases.CaseType.InputValue, "Case type has value");
            Assert.IsNotEmpty(page.Cases.Jurisdiction.InputValue, "Jurisdiction has value");
            Assert.IsNotEmpty(page.Cases.PropertyType.InputValue, "Property Type has value");
            Assert.IsNotEmpty(page.Cases.CaseCategory.InputValue, "Case category has value");
            Assert.IsNotEmpty(page.Cases.SubType.InputValue, "Sub type has value");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CriteriaSearchReturnsRecord(BrowserType browserType)
        {
            var data = new CaseScreenDesignerDbSetup().SetUp();
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainCpassRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithPermission(ApplicationTask.MaintainRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .Create();
            SignIn(driver, "/#/configuration/rules/screen-designer/cases", user.Username, user.Password);
            driver.WaitForAngularWithTimeout();

            var page = new CaseScreenDesignerSearchPageObject(driver);
            page.CriteriaRadioButton.Click();
            driver.WaitForAngular();

            //page.SubmitButtonCriteria.Click();
            //driver.WaitForAngular();

            //Assert.AreEqual(0, page.Grid.Rows.Count(), "correct record count displayed");

            page.Criteria.EnterAndSelect(data.Criteria[0].Id.ToString());
            driver.WaitForAngular();

            page.SubmitButtonCriteria.Click();
            driver.WaitForAngular();

            Assert.AreEqual(1, page.Grid.Rows.Count(), "correct record count displayed");
            Assert.AreEqual(page.Grid.Cell(0, 2).WithJs().GetInnerText(), data.Criteria[0].Id.ToString(), "Correct criteria number displayed");
            Assert.AreEqual(page.Grid.Cell(0, 3).WithJs().GetInnerText(), data.Criteria[0].Description, "Correct criteria number displayed");
        }

    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseScreenDesignerFilters : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CriteriaSearchCanBeFilteredByProgram(BrowserType browserType)
        {
            var data = new CaseScreenDesignerDbSetup().SetUp();
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainCpassRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithPermission(ApplicationTask.MaintainRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .Create();
            SignIn(driver, "/#/configuration/rules/screen-designer/cases", user.Username, user.Password);
            driver.WaitForAngularWithTimeout();

            var page = new CaseScreenDesignerSearchPageObject(driver);
            page.CriteriaRadioButton.Click();
            driver.WaitForAngular();
            var programFilter = new AngularMultiSelectGridFilter(driver, "searchResults", 5);
            programFilter.Open();
            driver.WaitForAngular();
            Assert.AreEqual(0, programFilter.ItemCount);

            page.Criteria.EnterAndSelect(data.Criteria[0].Id.ToString());
            driver.WaitForAngular();
            page.SubmitButtonCriteria.Click();
            driver.WaitForAngular();
            programFilter.Open();
            driver.WaitForAngular();
            Assert.AreEqual(0, programFilter.ItemCount);

            page.Criteria.EnterAndSelect(data.Criteria[1].Id.ToString());
            driver.WaitForAngular();
            page.SubmitButtonCriteria.Click();
            driver.WaitForAngular();
            programFilter.Open();
            driver.WaitForAngular();
            Assert.AreEqual(1, programFilter.ItemCount);

            programFilter.SelectOption(data.Program.Name);
            programFilter.Filter();
            driver.WaitForAngular();
            Assert.AreEqual(1, page.Grid.Rows.Count(), "correct record count displayed");

            page.SubmitButtonCriteria.Click();
            driver.WaitForAngular();
            Assert.AreEqual(0, programFilter.SelectedValues.Count());
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CriteriaSearchCanBeFilteredByJurisdiction(BrowserType browserType)
        {
            var data = new CaseScreenDesignerDbSetup().SetUp();
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainCpassRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithPermission(ApplicationTask.MaintainRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .Create();
            SignIn(driver, "/#/configuration/rules/screen-designer/cases", user.Username, user.Password);
            driver.WaitForAngularWithTimeout();

            var page = new CaseScreenDesignerSearchPageObject(driver);
            page.CriteriaRadioButton.Click();
            driver.WaitForAngular();
            var jurisdictionFilter = new AngularMultiSelectGridFilter(driver, "searchResults", 6);
            jurisdictionFilter.Open();
            driver.WaitForAngular();
            Assert.AreEqual(0, jurisdictionFilter.ItemCount);

            page.Criteria.EnterAndSelect(data.Criteria[0].Id.ToString());
            driver.WaitForAngular();
            page.SubmitButtonCriteria.Click();
            driver.WaitForAngular();
            jurisdictionFilter.Open();
            driver.WaitForAngular();
            Assert.AreEqual(0, jurisdictionFilter.ItemCount);

            page.Criteria.EnterAndSelect(data.Criteria[1].Id.ToString());
            driver.WaitForAngular();
            page.SubmitButtonCriteria.Click();
            driver.WaitForAngular();
            jurisdictionFilter.Open();
            driver.WaitForAngular();
            Assert.AreEqual(1, jurisdictionFilter.ItemCount);

            jurisdictionFilter.SelectOption(data.Jurisdiction.Name);
            jurisdictionFilter.Filter();
            driver.WaitForAngular();
            Assert.AreEqual(1, page.Grid.Rows.Count(), "correct record count displayed");

            page.SubmitButtonCriteria.Click();
            driver.WaitForAngular();
            Assert.AreEqual(0, jurisdictionFilter.SelectedValues.Count());
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseScreenDesignerPermissions : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShouldNotLoadIfMissingAppropriatePermissions(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainCpassRules, Deny.Create | Deny.Delete | Deny.Modify)
                       .WithPermission(ApplicationTask.MaintainRules, Deny.Create | Deny.Delete | Deny.Modify)
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .Create();
            SignIn(driver, "/#/configuration/rules/screen-designer/cases", user.Username, user.Password);
            driver.WaitForAngularWithTimeout();
            var page = new CaseScreenDesignerSearchPageObject(driver);
            Assert.False(page.PageIsShown);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShouldStillShowProtectedRulesOptionIfUserOnlyHaveMaintainRulesPermission(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainCpassRules, Deny.Create | Deny.Delete | Deny.Modify)
                       .WithPermission(ApplicationTask.MaintainRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .Create("usera");
            SignIn(driver, "/#/configuration/rules/screen-designer/cases", user.Username, user.Password);
            driver.WaitForAngularWithTimeout();
            var page = new CaseScreenDesignerSearchPageObject(driver);

            Assert.True(page.PageIsShown, "Page is shown");
            Assert.True(page.ProtectedCriteria.IsShown, "Protected criteria is shown by default");
            Assert.False(page.ProtectedCriteria.IsChecked, "Protected criteria is not checked by default");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShouldShowProtectedRulesOptionIfUserAllowedToSeeIt(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainCpassRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .Create();
            SignIn(driver, "/#/configuration/rules/screen-designer/cases", user.Username, user.Password);
            driver.WaitForAngularWithTimeout();
            var page = new CaseScreenDesignerSearchPageObject(driver);

            Assert.True(page.PageIsShown, "Page is shown");
            Assert.True(page.ProtectedCriteria.IsShown, "Protected Criteria is shown");
            Assert.True(page.ProtectedCriteria.IsChecked, "Protected Criteria is checked by default");
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseScreenDesignerDetail : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SectionsGridLoadsAppropriateSections(BrowserType browserType)
        {
            var data = new CaseScreenDesignerDbSetup().SetUp();

            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainCpassRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithPermission(ApplicationTask.MaintainRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .Create();
            SignIn(driver, $"/#/configuration/rules/screen-designer/cases/{data.CriteriaSectionsScenario1}", user.Username, user.Password);
            driver.WaitForAngularWithTimeout();

            var page = new CaseScreenDesignerMaintenancePageObject(driver);
            Assert.AreEqual(3, page.SectionGrid.Rows.Count);

            driver.Visit($"{Env.RootUrl}/#/configuration/rules/screen-designer/cases/{data.CriteriaSectionsScenario2}");
            driver.WaitForAngular();
            Assert.AreEqual(4, page.SectionGrid.Rows.Count);
        }
    }
}