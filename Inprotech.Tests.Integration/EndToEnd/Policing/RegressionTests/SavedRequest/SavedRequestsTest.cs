using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Policing;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.SavedRequest
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestType(TestTypes.Regression)]
    public class SavedRequestsTest : IntegrationTest
    {
        protected const string IpWhatWillBePoliced = "ip_WhatWillBePoliced";
        [SetUp]
        public void CreatePoliceAdminUser()
        {
            _loginUser = new Users()
                         .WithPermission(ApplicationTask.MaintainPolicingRequest)
                         .Create();
        }

        [TearDown]
        public void RestoreStoredProcedure()
        {
            DbSetup.Do(x => x.DbContext.RestoreStoredProcedureFromBackup(IpWhatWillBePoliced));
        }

        protected TestUser _loginUser;
        internal void AssertDisabledRemindersSection(RequestMaintainanceModal modal, bool isDisabled)
        {
            Assert.AreEqual(modal.StartDate().Input.WithJs().IsDisabled(), isDisabled);
            Assert.AreEqual(modal.EndDate().Input.WithJs().IsDisabled(), isDisabled);
            Assert.AreEqual(modal.DateLetters().Input.WithJs().IsDisabled(), isDisabled);
            Assert.AreEqual(modal.ForDays().WithJs().IsDisabled(), isDisabled);
            Assert.AreEqual(modal.DueDateOnly().WithJs().IsDisabled(), isDisabled);
        }

        internal void AssertEnabledAndSelection(RadioButtonOrCheckbox element, bool enabled, bool selected)
        {
            Assert.AreEqual(element.IsDisabled, !enabled);
            Assert.AreEqual(element.IsChecked, selected);
        }
    }
}