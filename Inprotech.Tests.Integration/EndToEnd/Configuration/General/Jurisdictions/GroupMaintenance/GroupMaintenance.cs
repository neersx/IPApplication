using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.GroupMaintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    class GroupMaintenance : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainGroup(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);  
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainJurisdiction)
                       .Create();
            new GroupMaintenanceDbSetUp().Prepare();

            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);

            var pageDetails = new GroupMaintenanceDetailPage(driver);
            var topic = pageDetails.GroupMembershipsTopic;

            var groupPicklist = new PickList(driver).ByName("jurisdictiongrouppicklist");
            var propertyTypePicklist = new PickList(driver).ByName("propertyTypePicklsit");

            #region Add button display
            pageDetails.GroupMembershipsTopic.SearchTextBox(driver).SendKeys(GroupMaintenanceDbSetUp.CountryInternal);
            pageDetails.GroupMembershipsTopic.SearchButton(driver).WithJs().Click();

            var searchResults = new KendoGrid(driver, "searchResults");

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(GroupMaintenanceDbSetUp.CountryInternal, searchResults.CellText(0, 1), "Search returns record matching code");

            pageDetails.GroupMembershipsTopic.BulkMenu(driver);
            pageDetails.GroupMembershipsTopic.SelectPageOnly(driver);
            pageDetails.GroupMembershipsTopic.EditButton(driver);
            topic.NavigateTo();
            Assert.IsFalse(topic.AddButton().Displayed);
            #endregion
            driver.WaitForAngularWithTimeout();
            pageDetails.GroupMembershipsTopic.LevelUp();
            pageDetails.GroupMembershipsTopic.SearchTextBox(driver).Clear();
            pageDetails.GroupMembershipsTopic.SearchTextBox(driver).SendKeys(GroupMaintenanceDbSetUp.GroupName1);
            pageDetails.GroupMembershipsTopic.SearchButton(driver).WithJs().Click();

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(GroupMaintenanceDbSetUp.GroupCode1, searchResults.CellText(0, 1), "Search returns record matching code");

            pageDetails.GroupMembershipsTopic.BulkMenu(driver);
            pageDetails.GroupMembershipsTopic.SelectPageOnly(driver);
            pageDetails.GroupMembershipsTopic.EditButton(driver);

            #region Include All Members Flag Checkbox
            topic.NavigateTo();
            pageDetails.GroupMembershipsTopic.AllMembersIncludeCheckBox(driver).WithJs().Click();
            Assert.IsFalse(pageDetails.GroupMembershipsTopic.SaveButton(driver).IsDisabled());
            #endregion

            #region Add Member In Group
            topic.NavigateTo();
            topic.Add();
            pageDetails.GroupMembershipsTopic.DateJoinedGroupTextBox(driver).SendKeys(Fixture.DateStringFromToday(-5));
            pageDetails.GroupMaintenanceDialog.Modal.FindElement(By.ClassName("btn-save")).TryClick();
            Assert.IsTrue(groupPicklist.HasError, "Required Field");

            Assert.IsFalse(pageDetails.GroupMembershipsTopic.DateBecameFullMemberTextBox(driver).IsDisabled());
            Assert.IsTrue(pageDetails.GroupMembershipsTopic.DateBecameAssociateMemberTextBox(driver).IsDisabled());
            groupPicklist.EnterAndSelect(GroupMaintenanceDbSetUp.GroupCode3);
            pageDetails.GroupMembershipsTopic.DateJoinedGroupTextBox(driver).Clear();
            pageDetails.GroupMembershipsTopic.DateJoinedGroupTextBox(driver).SendKeys(Fixture.DateStringFromToday(-5));
            pageDetails.GroupMembershipsTopic.DateLeftGroupTextBox(driver).SendKeys(Fixture.DateStringFromToday(-1));
            pageDetails.GroupMembershipsTopic.DateBecameFullMemberTextBox(driver).SendKeys(Fixture.DateStringFromToday(-3));
            pageDetails.GroupMembershipsTopic.DefaultSelectionCheckBox(driver).WithJs().Click();
            pageDetails.GroupMembershipsTopic.PreventEntryCheckBox(driver).WithJs().Click();
            pageDetails.GroupMembershipsTopic.AssociateMemberCheckBox(driver).WithJs().Click();
            pageDetails.GroupMembershipsTopic.DateBecameAssociateMemberTextBox(driver).SendKeys(Fixture.DateStringFromToday(-3));
            pageDetails.GroupMembershipsTopic.AddAnotherCheckBox(driver).WithJs().Click();
            propertyTypePicklist.EnterAndSelect(GroupMaintenanceDbSetUp.ValidProperty1);
            propertyTypePicklist.EnterAndSelect(GroupMaintenanceDbSetUp.ValidProperty2);
            pageDetails.GroupMaintenanceDialog.Modal.FindElement(By.ClassName("btn-save")).TryClick();
            groupPicklist.EnterAndSelect(GroupMaintenanceDbSetUp.CountryCode1);
            pageDetails.GroupMembershipsTopic.DateJoinedGroupTextBox(driver).SendKeys(Fixture.DateStringFromToday(-5));
            pageDetails.GroupMembershipsTopic.DateLeftGroupTextBox(driver).SendKeys(Fixture.DateStringFromToday(-1));
            pageDetails.GroupMembershipsTopic.DateBecameFullMemberTextBox(driver).SendKeys(Fixture.DateStringFromToday(-3));
            pageDetails.GroupMembershipsTopic.DefaultSelectionCheckBox(driver).WithJs().Click();
            pageDetails.GroupMembershipsTopic.PreventEntryCheckBox(driver).WithJs().Click();
            pageDetails.GroupMembershipsTopic.AssociateMemberCheckBox(driver).WithJs().Click();
            pageDetails.GroupMembershipsTopic.DateBecameAssociateMemberTextBox(driver).SendKeys(Fixture.DateStringFromToday(-3));
            Assert.IsTrue(pageDetails.GroupMembershipsTopic.DateBecameFullMemberTextBox(driver).IsDisabled());
            Assert.IsFalse(pageDetails.GroupMembershipsTopic.DateBecameAssociateMemberTextBox(driver).IsDisabled());
            Assert.AreEqual(pageDetails.GroupMembershipsTopic.DateBecameFullMemberTextBox(driver).Value(), string.Empty);
            pageDetails.GroupMembershipsTopic.AddAnotherCheckBox(driver).WithJs().Click();
            pageDetails.GroupMaintenanceDialog.Modal.FindElement(By.ClassName("btn-save")).TryClick();

            Assert.IsFalse(pageDetails.GroupMembershipsTopic.SaveButton(driver).IsDisabled());
            pageDetails.GroupMembershipsTopic.SaveButton(driver).ClickWithTimeout();

            topic.NavigateTo();
            var groupSearchResults = new KendoGrid(driver, "groupMembers");
         
            Assert.AreEqual(2, groupSearchResults.Rows.Count);
            Assert.AreEqual(GroupMaintenanceDbSetUp.CountryCode1, groupSearchResults.CellText(0, 1), "Search returns record matching Code");
            Assert.AreEqual(GroupMaintenanceDbSetUp.GroupCode3, groupSearchResults.CellText(1, 1), "Search returns record matching Code");
            Assert.AreEqual($"{GroupMaintenanceDbSetUp.ValidProperty2}, {GroupMaintenanceDbSetUp.ValidProperty1}", groupSearchResults.CellText(1, 8), "Search returns record matching Code");
            #endregion

            #region Add Group In Group
            topic.NavigateTo();
            driver.FindRadio("display-groups").Click();
            topic.Add();
            pageDetails.GroupMembershipsTopic.DateJoinedGroupTextBox(driver).SendKeys(Fixture.DateStringFromToday(-5));
            pageDetails.GroupMaintenanceDialog.Modal.FindElement(By.ClassName("btn-save")).TryClick();
            Assert.IsTrue(groupPicklist.HasError, "Required Field");

            groupPicklist.EnterAndSelect(GroupMaintenanceDbSetUp.GroupCode2);
            pageDetails.GroupMembershipsTopic.DateJoinedGroupTextBox(driver).Clear();
            pageDetails.GroupMembershipsTopic.DateJoinedGroupTextBox(driver).SendKeys(Fixture.DateStringFromToday(-5));
            pageDetails.GroupMembershipsTopic.DateLeftGroupTextBox(driver).SendKeys(Fixture.DateStringFromToday(-1));
            pageDetails.GroupMembershipsTopic.DefaultSelectionCheckBox(driver).WithJs().Click();
            pageDetails.GroupMembershipsTopic.PreventEntryCheckBox(driver).WithJs().Click();
            pageDetails.GroupMembershipsTopic.AssociateMemberCheckBox(driver).WithJs().Click();
            pageDetails.GroupMembershipsTopic.DateBecameAssociateMemberTextBox(driver).SendKeys(Fixture.DateStringFromToday(-3));
            pageDetails.GroupMembershipsTopic.AddAnotherCheckBox(driver).WithJs().Click();
            pageDetails.GroupMaintenanceDialog.Modal.FindElement(By.ClassName("btn-save")).TryClick();
            groupPicklist.EnterAndSelect(GroupMaintenanceDbSetUp.GroupCode3);
            pageDetails.GroupMembershipsTopic.DateJoinedGroupTextBox(driver).SendKeys(Fixture.DateStringFromToday(-5));
            pageDetails.GroupMembershipsTopic.DateLeftGroupTextBox(driver).SendKeys(Fixture.DateStringFromToday(-1));
            pageDetails.GroupMembershipsTopic.DateBecameFullMemberTextBox(driver).SendKeys(Fixture.DateStringFromToday(-3));
            pageDetails.GroupMembershipsTopic.DefaultSelectionCheckBox(driver).WithJs().Click();
            pageDetails.GroupMembershipsTopic.PreventEntryCheckBox(driver).WithJs().Click();
            pageDetails.GroupMembershipsTopic.AddAnotherCheckBox(driver).WithJs().Click();
            pageDetails.GroupMaintenanceDialog.Modal.FindElement(By.ClassName("btn-save")).TryClick();

            var popups = new CommonPopups(driver);
            driver.FindRadio("display-members").Click();
            popups.ConfirmModal.Cancel().ClickWithTimeout();

            Assert.IsFalse(pageDetails.GroupMembershipsTopic.SaveButton(driver).IsDisabled());
            pageDetails.GroupMembershipsTopic.SaveButton(driver).ClickWithTimeout();

            topic.NavigateTo();
            driver.FindRadio("display-groups").Click();
            Assert.AreEqual(2, groupSearchResults.Rows.Count);
            Assert.AreEqual(GroupMaintenanceDbSetUp.GroupCode2, groupSearchResults.CellText(0, 1), "Search returns record matching Code");
            Assert.AreEqual(GroupMaintenanceDbSetUp.GroupCode3, groupSearchResults.CellText(1, 1), "Search returns record matching Code");

            #endregion

            #region Add Group In Jurisdiction
            pageDetails.GroupMembershipsTopic.BackToSearch(driver);

            pageDetails.GroupMembershipsTopic.SearchTextBox(driver).Clear();
            pageDetails.GroupMembershipsTopic.SearchTextBox(driver).SendKeys(GroupMaintenanceDbSetUp.CountryName1);
            pageDetails.GroupMembershipsTopic.SearchButton(driver).WithJs().Click();

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(GroupMaintenanceDbSetUp.CountryCode1, searchResults.CellText(0, 1), "Search returns record matching code");

            pageDetails.GroupMembershipsTopic.BulkMenu(driver);
            pageDetails.GroupMembershipsTopic.SelectPageOnly(driver);
            pageDetails.GroupMembershipsTopic.EditButton(driver);

            topic.NavigateTo();
            topic.Add();

            groupPicklist.EnterAndSelect(GroupMaintenanceDbSetUp.GroupCode2);
            pageDetails.GroupMembershipsTopic.DateJoinedGroupTextBox(driver).SendKeys(Fixture.DateStringFromToday(-5));
            pageDetails.GroupMembershipsTopic.DateLeftGroupTextBox(driver).SendKeys(Fixture.DateStringFromToday(-1));
            pageDetails.GroupMembershipsTopic.DateBecameFullMemberTextBox(driver).SendKeys(Fixture.DateStringFromToday(-3));
            pageDetails.GroupMembershipsTopic.DefaultSelectionCheckBox(driver).WithJs().Click();
            pageDetails.GroupMembershipsTopic.PreventEntryCheckBox(driver).WithJs().Click();
            pageDetails.GroupMembershipsTopic.AddAnotherCheckBox(driver).WithJs().Click();
            pageDetails.GroupMaintenanceDialog.Modal.FindElement(By.ClassName("btn-save")).TryClick();

            groupPicklist.EnterAndSelect(GroupMaintenanceDbSetUp.GroupCode3);
            pageDetails.GroupMembershipsTopic.DateJoinedGroupTextBox(driver).SendKeys(Fixture.DateStringFromToday(-5));
            pageDetails.GroupMembershipsTopic.DateLeftGroupTextBox(driver).SendKeys(Fixture.DateStringFromToday(-1));
            pageDetails.GroupMembershipsTopic.DateBecameFullMemberTextBox(driver).SendKeys(Fixture.DateStringFromToday(-3));
            pageDetails.GroupMembershipsTopic.DefaultSelectionCheckBox(driver).WithJs().Click();
            pageDetails.GroupMembershipsTopic.PreventEntryCheckBox(driver).WithJs().Click();
            pageDetails.GroupMembershipsTopic.AddAnotherCheckBox(driver).WithJs().Click();
            pageDetails.GroupMaintenanceDialog.Modal.FindElement(By.ClassName("btn-save")).TryClick();

            Assert.IsFalse(pageDetails.GroupMembershipsTopic.SaveButton(driver).IsDisabled());
            pageDetails.GroupMembershipsTopic.SaveButton(driver).ClickWithTimeout();

            topic.NavigateTo();
            Assert.AreEqual(3, groupSearchResults.Rows.Count);
            Assert.AreEqual(GroupMaintenanceDbSetUp.GroupCode2, groupSearchResults.CellText(1, 1), "Search returns record matching Code");
            Assert.AreEqual(GroupMaintenanceDbSetUp.GroupCode3, groupSearchResults.CellText(2, 1), "Search returns record matching Code");
            #endregion

            #region Edit Group In Jurisdiction
            topic.NavigateTo();
            groupSearchResults.ClickEdit(1);
            Assert.False(groupPicklist.Enabled, "Group Picklist should be disabled.");
            Assert.AreEqual(groupPicklist.GetText(), GroupMaintenanceDbSetUp.GroupName2);
            Assert.IsNotNull(pageDetails.GroupMaintenanceDialog.Modal.FindElement(By.ClassName("btn-save")).GetAttribute("disabled"), "Ensure Apply Button is disabled");
            pageDetails.GroupMembershipsTopic.DateJoinedGroupTextBox(driver).Clear();
            pageDetails.GroupMembershipsTopic.DateJoinedGroupTextBox(driver).SendKeys(Fixture.DateStringFromToday(1));
            pageDetails.GroupMembershipsTopic.DateLeftGroupTextBox(driver).Clear();
            pageDetails.GroupMembershipsTopic.DateLeftGroupTextBox(driver).SendKeys(Fixture.DateStringFromToday(10));
            pageDetails.GroupMembershipsTopic.DateBecameFullMemberTextBox(driver).Clear();
            pageDetails.GroupMembershipsTopic.DateBecameFullMemberTextBox(driver).SendKeys(Fixture.DateStringFromToday(5));
            pageDetails.GroupMembershipsTopic.DefaultSelectionCheckBox(driver).WithJs().Click();
            pageDetails.GroupMembershipsTopic.PreventEntryCheckBox(driver).WithJs().Click();
            pageDetails.GroupMaintenanceDialog.Modal.FindElement(By.ClassName("btn-save")).TryClick();
            Assert.IsFalse(pageDetails.GroupMembershipsTopic.SaveButton(driver).IsDisabled());
            pageDetails.GroupMembershipsTopic.SaveButton(driver).ClickWithTimeout();

            topic.NavigateTo();
            Assert.AreEqual(3, groupSearchResults.Rows.Count);
            Assert.AreEqual(GroupMaintenanceDbSetUp.GroupCode2, groupSearchResults.CellText(1, 1), "Search returns record matching Code");
            #endregion

            #region Delete Group In Jurisdiction
            topic.NavigateTo();
            groupSearchResults.ToggleDelete(0);
            pageDetails.GroupMembershipsTopic.SaveButton(driver).ClickWithTimeout();
            topic.NavigateTo();
            Assert.AreEqual(2, groupSearchResults.Rows.Count);
            Assert.AreEqual(GroupMaintenanceDbSetUp.GroupCode3, groupSearchResults.CellText(1, 1), "Search returns record matching Code");
            #endregion

            #region Delete Member In Group
            pageDetails.GroupMembershipsTopic.BackToSearch(driver);

            pageDetails.GroupMembershipsTopic.SearchTextBox(driver).Clear();
            pageDetails.GroupMembershipsTopic.SearchTextBox(driver).SendKeys(GroupMaintenanceDbSetUp.GroupCode4);
            pageDetails.GroupMembershipsTopic.SearchButton(driver).WithJs().Click();

            pageDetails.GroupMembershipsTopic.BulkMenu(driver);
            pageDetails.GroupMembershipsTopic.SelectPageOnly(driver);
            pageDetails.GroupMembershipsTopic.EditButton(driver);

            topic.NavigateTo();
            groupSearchResults.ToggleDelete(0);
            groupSearchResults.ToggleDelete(1);

            pageDetails.GroupMembershipsTopic.SaveButton(driver).ClickWithTimeout();

            driver.WaitForAngularWithTimeout();
            topic.NavigateTo();
            Assert.AreEqual(0, groupSearchResults.Rows.Count);
            #endregion

            #region Delete Group from Group
            topic.NavigateTo();
            driver.FindRadio("display-groups").Click();
            groupSearchResults.ToggleDelete(0);

            pageDetails.GroupMembershipsTopic.SaveButton(driver).ClickWithTimeout();
            topic.NavigateTo();
            driver.FindRadio("display-groups").Click();
            Assert.AreEqual(0, groupSearchResults.Rows.Count);
            #endregion
        }
    }
}
