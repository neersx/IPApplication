using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.PriorArt.Maintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    class PriorArtSourceMaintenance : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CreateANewSource(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData();
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/reference-management?caseKey=" + data.Case.Id, user.Username, user.Password);
            var createSourcePage = new CreateSourcePageObjects(driver);

            createSourcePage.Source.Input.SelectByIndex(0);
            createSourcePage.Publication.SendKeys("this is a publication yo");
            createSourcePage.Description.Text = "this is a description yo";

            var priorArtMaintenancePage = new PriorArtMaintenancePageObjects(driver);
            priorArtMaintenancePage.SaveButton.Click();

            Assert.AreEqual("Your changes have been successfully saved.", priorArtMaintenancePage.NotificationMessage.Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainSource(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData();
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create | Allow.Modify).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/reference-management?priorartId=" + data.Source.Id + "caseKey=" + data.Case.Id, user.Username, user.Password);
            var createSourcePage = new CreateSourcePageObjects(driver);

            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Id("source")), "Expected Source button to be hidden");

            createSourcePage.Description.Input.SendKeys(Fixture.String(100));
            var page = new PriorArtMaintenancePageObjects(driver);
            page.SaveButton.Click();

            Assert.AreEqual("Your changes have been successfully saved.", page.NotificationMessage.Text, "Update source");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void ViewAssociatedPriorArt(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData(withAssociatedArt: true);
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/reference-management?priorartId=" + data.Source.Id + "caseKey=" + data.Case.Id, user.Username, user.Password);
            var page = new PriorArtMaintenancePageObjects(driver);
            page.GoToStep(2);
            driver.WaitForAngular();

            var list = page.CitationsList;
            Assert.AreEqual(2, list.Rows.Count);
            Assert.IsTrue(list.CellText(0, "Description").Contains("IPO-Description"));
            Assert.NotNull(list.Cell(0, 0).FindElement(By.CssSelector("span.cpa-icon-lightbulb-o")), "Expected IPO item to have bulb icon");
            Assert.IsTrue(list.CellText(1, "Description").Contains("NPL-Description"));
            Assert.NotNull(list.Cell(1, 0).FindElement(By.CssSelector("span.cpa-icon-book")), "Expected NPL item to have book icon");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainAssociatedPriorArt(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData(withAssociatedArt: true);
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create | Allow.Delete | Allow.Modify).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/reference-management?priorartId=" + data.Source.Id + "caseKey=" + data.Case.Id, user.Username, user.Password);
            var page = new PriorArtMaintenancePageObjects(driver);
            page.GoToStep(2);
            driver.WaitForAngular();
            page.CitationsList.ClickEdit(0);
            var openedPage = new PriorArtMaintenancePageObjects(driver);
            openedPage.SaveButton.Click();
            page.CitationsList.ClickDelete(0);
            var confirmDeleteDialog = new ConfirmModal(driver);
            confirmDeleteDialog.Yes().ClickWithTimeout();

            Assert.AreEqual("Your changes have been successfully saved.", page.MessageDiv.Text);

            var list = page.CitationsList;
            Assert.AreEqual(1, list.Rows.Count);
        }
    }
}