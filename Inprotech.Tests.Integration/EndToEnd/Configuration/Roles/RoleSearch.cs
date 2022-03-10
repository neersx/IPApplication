using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Roles
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class RoleSearch : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void SearchRoles(BrowserType browserType)
        {
            new RolesDbSetup().SetupData();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/user-configuration/roles");
            var page = new RolesPageObject(driver);
            driver.WaitForAngularWithTimeout();
            Assert.IsTrue(page.InternalCheckBox.IsChecked);
            Assert.IsFalse(page.InternalCheckBox.IsDisabled);
            Assert.IsTrue(page.ExternalCheckBox.IsChecked);
            Assert.IsFalse(page.ExternalCheckBox.IsDisabled);
            Assert.IsFalse(page.ExecuteCheckBox.IsChecked);
            Assert.IsTrue(page.ExecuteCheckBox.IsDisabled);
            Assert.IsFalse(page.InsertCheckBox.IsChecked);
            Assert.IsTrue(page.InsertCheckBox.IsDisabled);
            Assert.IsFalse(page.UpdateCheckBox.IsChecked);
            Assert.IsTrue(page.UpdateCheckBox.IsDisabled);
            Assert.IsFalse(page.DeleteCheckBox.IsChecked);
            Assert.IsTrue(page.DeleteCheckBox.IsDisabled);
            Assert.IsFalse(page.WebPartAccessCheckBox.IsChecked);
            Assert.IsTrue(page.WebPartAccessCheckBox.IsDisabled);
            Assert.IsFalse(page.WebPartMandatoryCheckBox.IsChecked);
            Assert.IsTrue(page.WebPartMandatoryCheckBox.IsDisabled);
            Assert.IsFalse(page.SubjectAccessCheckBox.IsChecked);
            Assert.IsTrue(page.SubjectAccessCheckBox.IsDisabled);
            page.RoleName.SendKeys("e2e");
            page.SearchButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            var grid = page.ResultGrid;
            Assert.AreEqual(2, grid.Rows.Count, "2 record is returned by search");
            page.ClearButton.ClickWithTimeout();
            page.RoleName.SendKeys("e2e");
            page.ExternalCheckBox.Click();
            page.SearchButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(1, grid.Rows.Count, "1 record is returned by search");
            page.ClearButton.ClickWithTimeout();
            page.RoleName.SendKeys("e2e");
            page.RoleDescription.SendKeys("e2e");
            page.TaskPicklist.EnterAndSelect("Maintain Case", 1);
            page.TaskPermissionSelect.SelectByText("Granted");
            Assert.IsFalse(page.ExecuteCheckBox.IsChecked);
            Assert.IsTrue(page.ExecuteCheckBox.IsDisabled);
            Assert.IsTrue(page.InsertCheckBox.IsChecked);
            Assert.IsFalse(page.InsertCheckBox.IsDisabled);
            Assert.IsTrue(page.UpdateCheckBox.IsChecked);
            Assert.IsFalse(page.UpdateCheckBox.IsDisabled);
            Assert.IsTrue(page.DeleteCheckBox.IsChecked);
            Assert.IsFalse(page.DeleteCheckBox.IsDisabled);
            page.WebPicklist.EnterAndSelect("Access Accounts");
            page.WebPartPermissionSelect.SelectByText("Granted");
            Assert.IsTrue(page.WebPartAccessCheckBox.IsChecked);
            Assert.IsFalse(page.WebPartAccessCheckBox.IsDisabled);
            Assert.IsTrue(page.WebPartMandatoryCheckBox.IsChecked);
            Assert.IsFalse(page.WebPartMandatoryCheckBox.IsDisabled);
            page.WebPartMandatoryCheckBox.Click();
            page.SubjectPicklist.EnterAndSelect("Attachments");
            page.SubjectPermissionSelect.SelectByText("Granted");
            Assert.IsTrue(page.SubjectAccessCheckBox.IsChecked);
            Assert.IsFalse(page.SubjectAccessCheckBox.IsDisabled);
            page.SearchButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(1, grid.Rows.Count, "1 record is returned by search");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ViewRoles(BrowserType browserType)
        {
            new RolesDbSetup().SetupData();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/user-configuration/roles");
            var page = new RolesPageObject(driver);
            driver.WaitForAngularWithTimeout();
            page.RoleName.SendKeys("e2e");
            page.SearchButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            var grid = page.ResultGrid;
            Assert.AreEqual(2, grid.Rows.Count, "2 record is returned by search");
            grid.Cell(1, grid.FindColByText("Role Name")).FindElement(By.TagName("a")).Click();
            driver.WaitForGridLoader();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("e2e role internal", page.RoleName.Value());
            Assert.AreEqual("e2e internal description", page.RoleDescriptionTextArea.Value());
            Assert.IsTrue(page.InternalRadioButton.IsChecked);
            Assert.IsFalse(page.ExternalRadioButton.IsChecked);
            page.Tasks.NavigateTo();
            var taskGrid = page.Tasks.TasksGrid;
            page.Tasks.ToggleDescriptionColumn.WithJs().Click();
            driver.WaitForAngularWithTimeout();
            page.Tasks.TogglePermissionSets.WithJs().Click();
            Assert.AreEqual(1, taskGrid.Rows.Count, "1 record is returned in the grid");
            Assert.IsTrue(taskGrid.HeaderColumnsText.Contains("Task Description"));
            Assert.IsTrue(taskGrid.Cell(0, taskGrid.FindColByText("Insert")).FindElement(By.TagName("input")).IsChecked());
            Assert.IsTrue(taskGrid.Cell(0, taskGrid.FindColByText("Update")).FindElement(By.TagName("input")).IsChecked());
            Assert.IsTrue(taskGrid.Cell(0, taskGrid.FindColByText("Delete")).FindElement(By.TagName("input")).IsChecked());
            page.Tasks.TogglePermissionSets.WithJs().Click();
            driver.WaitForGridLoader();
            driver.WaitForAngularWithTimeout();
            Assert.AreNotEqual(1, taskGrid.Rows.Count, "All record is returned in the grid");
            page.Tasks.SearchTasks.SendKeys("Access Documents from DMS");
            page.Tasks.SearchButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(1, taskGrid.Rows.Count, "1 record is returned in the grid");
            var featureFilter = new AngularMultiSelectGridFilter(driver, "taskGrid", 7);
            featureFilter.Open();
            featureFilter.SelectOption("Document Management");
            featureFilter.Filter();
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            Assert.AreEqual(1, taskGrid.Rows.Count, "1 record is returned in the grid");
            var subFeatureFilter = new AngularMultiSelectGridFilter(driver, "taskGrid", 8);
            subFeatureFilter.Open();
            subFeatureFilter.SelectOption("DMS Integration");
            subFeatureFilter.Filter();
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            Assert.AreEqual(1, taskGrid.Rows.Count, "1 record is returned in the grid");
            var releaseFilter = new AngularMultiSelectGridFilter(driver, "taskGrid", 9);
            releaseFilter.Open();
            releaseFilter.SelectOption("(empty)");
            releaseFilter.Filter();
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            Assert.AreEqual(1, taskGrid.Rows.Count, "1 record is returned in the grid");
            page.WebParts.NavigateTo();
            driver.WaitForAngularWithTimeout();
            var webPartGrid = page.WebParts.WebPartsGrid;
            Assert.IsTrue(webPartGrid.HeaderColumnsText.Contains("Web Part Description"));
            Assert.IsTrue(webPartGrid.Cell(0, webPartGrid.FindColByText("Access")).FindElement(By.TagName("input")).IsChecked());
            var webPartFeatureFilter = new AngularMultiSelectGridFilter(driver, "webPartGrid", 4);
            webPartFeatureFilter.Open();
            webPartFeatureFilter.SelectOption("WIP Management");
            webPartFeatureFilter.Filter();
            Assert.AreEqual(1, webPartGrid.Rows.Count, "1 record is returned in the grid");
            var webPartSubFeatureFilter = new AngularMultiSelectGridFilter(driver, "webPartGrid", 5);
            webPartSubFeatureFilter.Open();
            webPartSubFeatureFilter.SelectOption("WIP Overview");
            webPartSubFeatureFilter.Filter();
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            Assert.AreEqual(1, webPartGrid.Rows.Count, "1 record is returned in the grid");
            webPartSubFeatureFilter.Open();
            webPartSubFeatureFilter.Clear();
            Assert.AreEqual(1, webPartGrid.Rows.Count, "1 record is returned in the grid");
            driver.WaitForGridLoader();
            webPartFeatureFilter.Open();
            webPartFeatureFilter.Clear();
            Assert.AreNotEqual(1, webPartGrid.Rows.Count, "All record is returned in the grid");
            page.Subjects.NavigateTo();
            driver.WaitForAngularWithTimeout();
            var subjectGrid = page.Subjects.SubjectsGrid;
            Assert.IsTrue(subjectGrid.Cell(0, subjectGrid.FindColByText("Access")).FindElement(By.TagName("input")).IsChecked());
            page.SkipToFirst.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            Assert.AreEqual("e2e role external", page.RoleName.Value());
            Assert.AreEqual("e2e external description", page.RoleDescriptionTextArea.Value());
            Assert.IsFalse(page.InternalRadioButton.IsChecked);
            Assert.IsTrue(page.ExternalRadioButton.IsChecked);
        }
    }
}