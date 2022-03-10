using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.PriorArt.Maintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    class MaintainLinkedCases : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void LinkCaseToPriorArt(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData(withLinkedCases: true);
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create | Allow.Modify).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/reference-management?priorartId=" + data.Ipo.Id + "caseKey=" + data.Case.Id, user.Username, user.Password);

            var maintenancePage = new PriorArtMaintenancePageObjects(driver);
            maintenancePage.GoToStep(3);

            driver.WaitForAngular();

            var linkedCasesList = maintenancePage.LinkedCasesList;
            Assert.AreEqual(1, linkedCasesList.Rows.Count);

            maintenancePage.LinkCasesButton.Click();

            var linkCasesDialog = new LinkCasesDialog(driver, "addLinkedCases");
            Assert.True(linkCasesDialog.SaveButton.IsDisabled(), "Expected Save button to be initially disabled.");

            var casePicklist = linkCasesDialog.CaseReference;
            casePicklist.SendKeys(Keys.ArrowDown);
            casePicklist.SendKeys(Keys.ArrowDown);
            casePicklist.SendKeys(Keys.Enter);
            var linkedCase = casePicklist.InputValue;

            linkCasesDialog.AddAnother.Click();
            linkCasesDialog.SaveButton.WithJs().Click();

            Assert.AreEqual(string.Empty, casePicklist.InputValue, "Expected case picklist to be cleared.");
            linkCasesDialog.CloseModal();

            driver.WaitForAngular();

            linkedCasesList = maintenancePage.LinkedCasesList;
            Assert.AreEqual(2, linkedCasesList.Rows.Count);

            maintenancePage.LinkCasesButton.Click();
            linkCasesDialog.CaseFamily.SendKeys(data.Family.Id);
            linkCasesDialog.CaseFamily.SendKeys(Keys.ArrowDown);
            linkCasesDialog.CaseFamily.SendKeys(Keys.Enter);
            linkCasesDialog.SaveButton.WithJs().Click();
            Assert.AreEqual(3, linkedCasesList.Rows.Count, "New Family cases are linked.");

            maintenancePage.LinkCasesButton.Click();
            linkCasesDialog.CaseLists.SendKeys(data.CaseList.Name);
            linkCasesDialog.CaseLists.SendKeys(Keys.ArrowDown);
            linkCasesDialog.CaseLists.SendKeys(Keys.Enter);
            linkCasesDialog.SaveButton.WithJs().Click();
            Assert.AreEqual(4, linkedCasesList.Rows.Count, "New Case List references are returned.");

            maintenancePage.LinkCasesButton.Click();
            linkCasesDialog.CaseName.SendKeys(data.Name.NameCode);
            linkCasesDialog.CaseName.SendKeys(Keys.ArrowDown);
            linkCasesDialog.CaseName.SendKeys(Keys.Enter);
            linkCasesDialog.NameType.SendKeys(data.NameType.NameTypeCode);
            linkCasesDialog.NameType.SendKeys(Keys.ArrowDown);
            linkCasesDialog.NameType.SendKeys(Keys.Enter);
            linkCasesDialog.SaveButton.WithJs().Click();
            Assert.AreEqual(5, linkedCasesList.Rows.Count, "New Name List references are returned.");

            CheckFilter(driver, linkedCasesList, linkedCasesList.FindColByText("Case Ref"), data.Case.Irn);
            CheckFilter(driver, linkedCasesList, linkedCasesList.FindColByText("Official Number"), data.Case.CurrentOfficialNumber);
            CheckFilter(driver, linkedCasesList, linkedCasesList.FindColByText("Jurisdiction"), data.Case.Country.Name);
            CheckFilter(driver, linkedCasesList, linkedCasesList.FindColByText("Prior Art Status"), data.PriorArtStatusCode.Name);
            CheckFilter(driver, linkedCasesList, linkedCasesList.FindColByText("Family"), data.Family.Name);
            CheckFilter(driver, linkedCasesList, linkedCasesList.FindColByText("Case List"), data.CaseList.Name);
            CheckFilter(driver, linkedCasesList, linkedCasesList.FindColByText("Linked via Names"), data.Name.LastName);

            maintenancePage.LinkCasesButton.Click();
            linkCasesDialog.CaseReference.SendKeys(linkedCase);
            linkCasesDialog.CaseReference.SendKeys(Keys.ArrowDown);
            linkCasesDialog.CaseReference.SendKeys(Keys.Enter);
            linkCasesDialog.CaseFamily.SendKeys(data.Family.Id);
            linkCasesDialog.CaseFamily.SendKeys(Keys.ArrowDown);
            linkCasesDialog.CaseFamily.SendKeys(Keys.Enter);
            linkCasesDialog.CaseLists.SendKeys(data.CaseList.Name);
            linkCasesDialog.CaseLists.SendKeys(Keys.ArrowDown);
            linkCasesDialog.CaseLists.SendKeys(Keys.Enter);
            linkCasesDialog.CaseName.SendKeys(data.Name.NameCode);
            linkCasesDialog.CaseName.SendKeys(Keys.ArrowDown);
            linkCasesDialog.CaseName.SendKeys(Keys.Enter);
            linkCasesDialog.NameType.SendKeys(data.NameType.NameTypeCode);
            linkCasesDialog.NameType.SendKeys(Keys.ArrowDown);
            linkCasesDialog.NameType.SendKeys(Keys.Enter);
            linkCasesDialog.SaveButton.WithJs().Click();
            var popups = new CommonPopups(driver);
            var alertMessage = popups.AlertModal.Description;
            Assert.True(alertMessage.Contains(linkedCase),
                        $"Duplicate case reference {linkedCase} should be displayed in message but was {alertMessage}");
            Assert.True(alertMessage.Contains(data.Family.Name),
                        $"Duplicate family {data.Family.Name} should be displayed in message but was {alertMessage}");
            Assert.True(alertMessage.Contains(data.CaseList.Name),
                        $"Duplicate case list {data.CaseList.Name} should be displayed in message but was {alertMessage}");
            Assert.True(alertMessage.Contains(data.Name.LastName),
                        $"Duplicate case list {data.Name.LastName} should be displayed in message but was {alertMessage}");
            popups.AlertModal.Ok();

            linkCasesDialog.CloseModal();
            
            Assert.AreEqual(1, maintenancePage.LinkedCasesList.Cell(0, 1).FindElements(By.TagName("ipx-icon")).Count);
            Assert.AreEqual(0, maintenancePage.LinkedCasesList.Cell(1, 1).FindElements(By.TagName("ipx-icon")).Count);
            maintenancePage.LinkedCasesList.SelectRow(0);
            maintenancePage.LinkedCasesList.ActionMenu.OpenOrClose();
            driver.WaitForAngular();

            Assert.True(maintenancePage.ChangeFirstLinked.Disabled());
            maintenancePage.LinkedCasesList.SelectRow(0);
            driver.WaitForAngular();

            maintenancePage.LinkedCasesList.SelectRow(1);
            driver.WaitForAngular();
            maintenancePage.LinkedCasesList.ActionMenu.OpenOrClose();

            Assert.False(maintenancePage.ChangeFirstLinked.Disabled());

            maintenancePage.ChangeFirstLinked.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.True(maintenancePage.IsFirstLinkedModal.Modal.Displayed);

            maintenancePage.IsFirstLinkedModal.ApplyButton.ClickWithTimeout();
            driver.WaitForAngular();

            Assert.AreEqual(0, maintenancePage.LinkedCasesList.Cell(0, 1).FindElements(By.TagName("ipx-icon")).Count);
            Assert.AreEqual(1, maintenancePage.LinkedCasesList.Cell(1, 1).FindElements(By.TagName("ipx-icon")).Count);

            maintenancePage.LinkedCasesList.SelectRow(1);
            maintenancePage.LinkedCasesList.SelectRow(2);
            maintenancePage.LinkedCasesList.SelectRow(3);
            driver.WaitForAngular();
            maintenancePage.LinkedCasesList.ActionMenu.OpenOrClose();
            maintenancePage.UpdatePriorArtStatus.Click();
            maintenancePage.UpdatePriorArtStatusModal.Status.SendKeys(data.PriorArtStatusCode.Name);
            maintenancePage.UpdatePriorArtStatusModal.Status.SendKeys(Keys.Down);
            maintenancePage.UpdatePriorArtStatusModal.Status.SendKeys(Keys.Enter);
            maintenancePage.UpdatePriorArtStatusModal.SaveButton.ClickWithTimeout();

            Assert.AreEqual(data.PriorArtStatusCode.Name, maintenancePage.LinkedCasesList.Cell(0, 6).Text);
            Assert.AreEqual(data.PriorArtStatusCode.Name, maintenancePage.LinkedCasesList.Cell(2, 6).Text);
            Assert.AreEqual(data.PriorArtStatusCode.Name, maintenancePage.LinkedCasesList.Cell(3, 6).Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void RemoveLinkedCases(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData(withLinkedCases: true);
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create | Allow.Modify | Allow.Delete).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/reference-management?priorartId=" + data.Ipo.Id + "caseKey=" + data.Case.Id, user.Username, user.Password);

            var maintenancePage = new PriorArtMaintenancePageObjects(driver);
            maintenancePage.GoToStep(3);

            driver.WaitForAngular();

            maintenancePage.LinkCasesButton.Click();
            var linkCasesDialog = new LinkCasesDialog(driver, "addLinkedCases");
            var casePicklist = linkCasesDialog.CaseReference;
            casePicklist.SendKeys(Keys.ArrowDown);
            casePicklist.SendKeys(Keys.ArrowDown);
            casePicklist.SendKeys(Keys.Enter);
            linkCasesDialog.SaveButton.WithJs().Click();
            driver.WaitForAngular();

            maintenancePage.LinkedCasesList.SelectRow(0);
            maintenancePage.LinkedCasesList.ActionMenu.OpenOrClose();
            driver.WaitForAngular();
            Assert.True(maintenancePage.RemoveLinkedCases.Enabled);
            maintenancePage.RemoveLinkedCases.ClickWithTimeout();
            driver.WaitForAngular();
            var popups = new CommonPopups(driver);
            popups.ConfirmModal.Yes().Click();
            
            driver.WaitForAngular();
            Assert.AreEqual(1, maintenancePage.LinkedCasesList.Rows.Count, "Linked Case is successfully removed via bulk action menu");
        }

        void CheckFilter(NgWebDriver driver, AngularKendoGrid grid, int colIndex, string filter)
        {
            var caseFilter = new AngularMultiSelectGridFilter(driver, "linkedCasesList", colIndex);
            caseFilter.Open();
            var filterCount = caseFilter.ItemCount;
            caseFilter.SelectOption(filter);
            caseFilter.Filter();
            Assert.True(grid.ColumnValues(colIndex, grid.Rows.Count).All(_ => _.Contains(filter)), $"Expected all values within the column to contain {filter}");
            caseFilter.Open();
            Assert.AreEqual(filterCount, caseFilter.ItemCount, $"Expected filter to have {filterCount} options but only had {caseFilter.ItemCount}");
            caseFilter.Clear();
        }
    }
}