using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.EventControl
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class GetEventControl : IntegrationTest
    {
        [Test]
        public void GetEventControlData()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();
                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    f.ChildCriteriaId
                };
            });

            var result = ApiClient.Get<dynamic>("configuration/rules/workflows/" + data.ChildCriteriaId + "/eventcontrol/" + data.EventId);
            
            Assert.AreEqual(data.ChildCriteriaId, result.criteriaId.Value, "Correct event data should be returned");
            Assert.AreEqual(data.EventId, result.eventId.Value, "Correct event data should be returned");
            CheckEventControlData(result);

            Assert.IsNotNull(result.parent, "Parent event data should be returned");
            Assert.AreEqual(data.CriteriaId, result.parent.criteriaId.Value, "Correct Parent event data should be returned");
            Assert.AreEqual(data.EventId, result.parent.eventId.Value, "Correct Parent event data should be returned");
            CheckEventControlData(result.parent);
        }

        void CheckEventControlData(dynamic result)
        {
            Assert.IsNotNull(result.overview, "Overview data should be returned");
            Assert.IsNotNull(result.standingInstruction, "StandingInstruction data should be returned");
            Assert.IsNotNull(result.dueDateCalcSettings, "DueDateCalcSettings data should be returned");
            Assert.IsNotNull(result.syncedEventSettings, "SyncedEventSettings data should be returned");
            Assert.IsNotNull(result.charges, "Charges data should be returned");
            Assert.IsNotNull(result.nameChangeSettings, "NameChangeSettings data should be returned");
            Assert.IsNotNull(result.changeAction, "ChangeAction data should be returned");
        }
    }
}
