using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.HostedComponents.ContactActivity;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.CommonPageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.PriorArt.Maintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    class PriorArtMaintenance : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteAPriorArt(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData();
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create | Allow.Delete).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/reference-management?priorartId=" + data.Source.Id + "&caseKey=" + data.Case.Id, user.Username, user.Password);
            
            var priorArtMaintenancePage = new PriorArtMaintenancePageObjects(driver);

            Assert.False(priorArtMaintenancePage.DeleteButton.IsDisabled());

            priorArtMaintenancePage.DeleteButton.Click();
            var confirmDeleteDialog = new AngularConfirmDeleteModal(driver);
            confirmDeleteDialog.Delete.ClickWithTimeout();

            Assert.AreEqual("Your changes have been successfully saved.", priorArtMaintenancePage.MessageDiv.Text);
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainNonPatentLiterature(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData();
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/reference-management?priorartId=" + data.NonPatentLiterature.Id + "caseKey="+ data.Case.Id, user.Username, user.Password);
            var createSourcePage = new CreateSourcePageObjects(driver);

            Assert.True(createSourcePage.LiteratureButton.GetAttributeValue<string>("class") == "btn btn-success", "Page goes to the NPL details.");

            var maintenancePage = new PriorArtMaintenancePageObjects(driver);
            maintenancePage.GoToStep(2);
            var associatePriorArtPage = new AssociatePriorArtPageObjects(driver);
            associatePriorArtPage.SearchButton.Click();
            var priorArtPage = new PriorArtPageObjects(driver);
            Assert.AreEqual(data.NonPatentLiterature.Description, priorArtPage.SourceName.WithJs().GetInnerText(), "Shows the right source in search and search page is loaded correctly.");
            priorArtPage.SearchButton.Click();
            priorArtPage.CloseButton.Click();
            var stepsContent = driver.FindElement(By.CssSelector("div.steps"));
            Assert.NotNull(stepsContent.FindElement(By.TagName("ipx-citations-list")), "Ensure after closing search page goes back to the Associate Prior Art step.");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void LinkedCases(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData(withLinkedCases: true);
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/reference-management?priorartId=" + data.Ipo.Id + "caseKey="+ data.Case.Id, user.Username, user.Password);

            var maintenancePage = new PriorArtMaintenancePageObjects(driver);
            maintenancePage.GoToStep(3);
           
            driver.WaitForAngular();

            Assert.AreEqual(1, maintenancePage.LinkedCasesList.Rows.Count);
            Assert.AreEqual(data.Case.Irn, maintenancePage.LinkedCasesList.CellText(0, "Case Ref"));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainIpo(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData(withAssociatedSource: true);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create | Allow.Modify)
                        .Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/reference-management?priorartId=" + data.Ipo.Id + "caseKey=", user.Username, user.Password);
            var createSourcePage = new CreateSourcePageObjects(driver);

            Assert.True(createSourcePage.IpoIssuedButton.GetAttributeValue<string>("class") == "btn btn-success");
            Assert.AreEqual(data.Ipo.Description, createSourcePage.Description.Text);
            Assert.AreEqual(data.Ipo.Name, createSourcePage.InventorName.Text);
            Assert.AreEqual(data.Ipo.OfficialNumber, createSourcePage.OfficialNumber.Text);
            Assert.AreEqual(data.Ipo.Kind, createSourcePage.KindCode.Text);
            Assert.AreEqual(data.Ipo.Title, createSourcePage.Title.Text);
            Assert.AreEqual(data.Ipo.RefDocumentParts, createSourcePage.ReferenceParts.Text);
            Assert.AreEqual(data.Ipo.Abstract, createSourcePage.Abstract.Text);
            Assert.AreEqual(data.Ipo.Citation, createSourcePage.Citation.Text);
            Assert.AreEqual(data.Ipo.Comments, createSourcePage.Comments.Text);

            var newDescription = Fixture.String(10);
            createSourcePage.Description.Text = newDescription;
            driver.WaitForAngular();
            
            var newName = Fixture.String(10);
            createSourcePage.InventorName.Text = newName;
            driver.WaitForAngular();

            var newKind = Fixture.String(3);
            createSourcePage.KindCode.Text = newKind;
            driver.WaitForAngular();

            var newComments = Fixture.String(10);
            createSourcePage.Comments.Text = newComments;
            driver.WaitForAngular();

            var newAbstract = Fixture.String(10);
            createSourcePage.Abstract.Text = newAbstract;
            driver.WaitForAngular();

            Fixture.String(10);
            createSourcePage.ReferenceParts.Text = Fixture.String(10);
            driver.WaitForAngular();

            var newCitation = Fixture.String(10);
            createSourcePage.Citation.Text = newCitation;
            driver.WaitForAngular();

            driver.FindElement(By.CssSelector("ipx-save-button")).ClickWithTimeout();
            driver.WaitForAngular();
            
            Assert.AreEqual(newDescription, createSourcePage.Description.Text);
            Assert.AreEqual(newName, createSourcePage.InventorName.Text);
            Assert.AreEqual(newKind, createSourcePage.KindCode.Text);
            Assert.AreEqual(newAbstract, createSourcePage.Abstract.Text);
            Assert.AreEqual(newCitation, createSourcePage.Citation.Text);
            Assert.AreEqual(newComments, createSourcePage.Comments.Text);

            var page = new PriorArtMaintenancePageObjects(driver);
            page.GoToStep(2);
            driver.WaitForAngular();

            var list = page.CitationsList;
            Assert.AreEqual(1, list.Rows.Count);
            Assert.AreEqual("Source-Desc", list.CellText(0, "Description"));
            Assert.AreEqual(data.Source.SourceType.Name, list.CellText(0, "Source"));
            Assert.AreEqual(data.Source.IssuingCountry.Name, list.CellText(0, "Jurisdiction"));
        }
    }
}
