using System;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.DateOfLaw
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ValidDateOfLawPicklist : IntegrationTest
    {
        public dynamic SetUpData;

        [SetUp]
        public void Setup()
        {
            _dateOfLawPicklistsDbSetup = new ValidDateOfLawPicklistsDbSetup();
            SetUpData = _dateOfLawPicklistsDbSetup.PrepareValidDateOfLawData();
        }

        ValidDateOfLawPicklistsDbSetup _dateOfLawPicklistsDbSetup;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ValidDateOfLawPicklistsOperations(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");
            var pageDetails = new ValidDateOfLawDetailPage(driver);
            pageDetails.DefaultsTopic.Jurisdiction.EnterAndSelect(ValidDateOfLawPicklistsDbSetup.JurisdictionDescription);
            pageDetails.DefaultsTopic.PropertyType.EnterAndSelect(ValidDateOfLawPicklistsDbSetup.PropertyTypeDescription);

            #region Add Date Of Law
            pageDetails.DefaultsTopic.DateOfLaw.OpenPickList(string.Empty);
            pageDetails.DefaultsTopic.AddButton(driver).Click();
            pageDetails.DefaultsTopic.DateOfLawDatePicker(driver).SendKeys(DateTime.Today.AddDays(-1).ToString("yyyy-MM-dd"));
            pageDetails.DefaultsTopic.DeterminingEvent.EnterAndSelect(ValidDateOfLawPicklistsDbSetup.LawEventDescription);
            pageDetails.DefaultsTopic.RetrospectiveEvent.EnterAndSelect(ValidDateOfLawPicklistsDbSetup.RetroEventDescription);
            pageDetails.DefaultsTopic.AddAffectedActionButton(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.RetrospectiveAction.EnterAndSelect(ValidDateOfLawPicklistsDbSetup.ActionDescription1);
            pageDetails.SaveButton.ClickWithTimeout();

            pageDetails.DefaultsTopic.DateOfLaw.SearchFor(DateTime.Today.AddDays(-1).ToString("dd-MMM-yyyy"));
            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            #endregion

            #region Edit Date Of Law
            pageDetails.DefaultsTopic.DateOfLaw.EditRow(0);
            Assert.IsTrue(pageDetails.DefaultsTopic.DateOfLawDatePicker(driver).GetAttribute("disabled").Equals("true"), "Ensure disabled");
            Assert.IsTrue(pageDetails.DefaultsTopic.JurisdictionTextBox(driver).GetAttribute("disabled").Equals("true"), "Ensure disabled");
            Assert.IsTrue(pageDetails.DefaultsTopic.PropertyTypeTextBox(driver).GetAttribute("disabled").Equals("true"), "Ensure disabled");
            pageDetails.DefaultsTopic.DeterminingEvent.EnterAndSelect(ValidDateOfLawPicklistsDbSetup.LawEventDescription1);
            pageDetails.DefaultsTopic.RetrospectiveEvent.EnterAndSelect(ValidDateOfLawPicklistsDbSetup.RetroEventDescription1);
            pageDetails.DefaultsTopic.RetrospectiveAction.EnterAndSelect(ValidDateOfLawPicklistsDbSetup.ActionDescription2);
            pageDetails.SaveButton.ClickWithTimeout();

            pageDetails.DefaultsTopic.DateOfLaw.SearchFor(DateTime.Today.AddDays(-1).ToString("dd-MMM-yyyy"));
            Assert.AreEqual(1, searchResults.Rows.Count);
            pageDetails.DefaultsTopic.DateOfLaw.EditRow(0);
            pageDetails.DefaultsTopic.DeleteAction(driver).ClickWithTimeout();
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.DateOfLaw.EditRow(0);
            var searchResults1 = new KendoGrid(driver, "affectedActions");
            Assert.AreEqual(0, searchResults1.Rows.Count);
            pageDetails.Discard();
            #endregion

            #region Delete Date Of Law which is in use
            pageDetails.DefaultsTopic.DateOfLaw.SearchFor(SetUpData.Date.ToString("dd-MMM-yyyy"));
            Assert.AreEqual(1, searchResults.Rows.Count);
            pageDetails.DefaultsTopic.DateOfLaw.DeleteRow(0);
            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().WithJs().Click();
            popups.AlertModal.Ok();

            pageDetails.DefaultsTopic.DateOfLaw.SearchFor(SetUpData.Date.ToString("dd-MMM-yyyy"));
            Assert.AreEqual(1, searchResults.Rows.Count);
            #endregion

            #region Delete Date Of Law which is not in use
            pageDetails.DefaultsTopic.DateOfLaw.SearchFor(DateTime.Today.AddDays(-1).ToString("dd-MMM-yyyy"));
            Assert.AreEqual(1, searchResults.Rows.Count);
            pageDetails.DefaultsTopic.DateOfLaw.DeleteRow(0);
            popups.ConfirmDeleteModal.Delete().WithJs().Click();

            pageDetails.DefaultsTopic.DateOfLaw.SearchFor(DateTime.Today.AddDays(-1).ToString("dd-MMM-yyyy"));
            Assert.AreEqual(0, searchResults.Rows.Count);
            #endregion
        }
    }
}
