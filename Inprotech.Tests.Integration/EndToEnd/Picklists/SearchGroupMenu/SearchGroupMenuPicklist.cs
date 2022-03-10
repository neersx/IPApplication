using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.SearchGroupMenu
{
    [TestFixture]
    [Category(Categories.E2E)]
    public class SearchGroupMenuPicklist : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddUpdateDeleteSearchGroupMenuPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/case/search");

            var saveSearch = new SearchGroupMenuPicklistDetailPage(driver);
            saveSearch.CaseReference.SendKeys("1234");
            saveSearch.SaveSearchButton().ClickWithTimeout();

            var picklist = new AngularPicklist(driver).ById("searchmenu-picklist");
            picklist.OpenPickList(string.Empty);
            picklist.AddAngularPicklistItem();
            saveSearch.DescriptionTextArea().SendKeys("e2e-add");
            picklist.Apply();
            picklist.SearchFor("e2e-add");
            Assert.AreEqual("e2e-add", picklist.SearchGrid.CellText(0, 0), "Should show added description");
            picklist.EditRow(0);
            saveSearch.DescriptionTextArea().Clear();
            saveSearch.DescriptionTextArea().SendKeys("e2e-edit");
            picklist.Apply();
            saveSearch.CloseButton.WithJs().Click();
            picklist.SearchFor("e2e-edit");
            Assert.AreEqual("e2e-edit", picklist.SearchGrid.CellText(0, 0), "Should show added description");
            picklist.DeleteRow(0);
            var popups = new CommonPopups(driver);
            popups.ConfirmNgDeleteModal.Delete.WithJs().Click();

            picklist.SearchFor("e2e-edit");
            Assert.IsEmpty(picklist.SearchGrid.Rows);
        }
    }
}
