using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using InprotechKaizen.Model.DataValidation;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.Actions.Editing
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedActionComponentEditing : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            var setup = new CaseDetailsActionsDbSetup();

            _currentIsImmediately = setup.IsPoliceImmediately;
            _eventLinksToWorkflowWizard = setup.EventLinksToWorkflowWizard;
            setup.EnsureEventLogDoesNotExist();
            DataValidations = new List<DataValidation>();
        }

        [TearDown]
        public void TearDown()
        {
            var setup = new CaseDetailsActionsDbSetup();

            setup.IsPoliceImmediately = _currentIsImmediately;
            setup.EventLinksToWorkflowWizard = _eventLinksToWorkflowWizard;

            setup.RevertEventLog();
            setup.EnsureEventLogDoesNotExist();
            setup.ResetDataValidations(DataValidations);
        }

        bool _currentIsImmediately;
        bool _eventLinksToWorkflowWizard;
        List<DataValidation> DataValidations { get; set; }

        public void TurnOffDataValidations()
        {
            DbSetup.Do(db =>
            {
                DataValidations = db.DbContext.Set<DataValidation>().Where(_ => _.InUseFlag).ToList();
                foreach (var dataValidation in DataValidations) dataValidation.InUseFlag = false;
                db.DbContext.SaveChanges();
            });
        }

        internal static void AssertRequestsIsPoliceImmediately(HostedTestPageObject page)
        {
            var requestMessage = page.LifeCycleMessages.Last();
            Assert.AreEqual("isPoliceImmediately", requestMessage.Payload);
            Assert.AreEqual("onRequestData", requestMessage.Action);
        }
    }
}