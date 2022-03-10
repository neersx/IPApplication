using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.EventControl
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class EventControlDefaultsTest : IntegrationTest
    {
        [Test]
        public void DueDateCalcSettingsDefaultedWhenCreatingEvent()
        {
            var data = DbSetup.Do(setup =>
                                      {
                                          var eventBuilder = new EventBuilder(setup.DbContext);
                                          var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                                          var criteria = criteriaBuilder.Create("parent");

                                          var evnt1 = eventBuilder.Create(recalcEventData: false, suppressCalculation: false);
                                          var evnt2 = eventBuilder.Create(recalcEventData: true, suppressCalculation: true);

                                          return new
                                                     {
                                                         OffEventId = evnt1.Id,
                                                         OnEventId = evnt2.Id,
                                                         CriteriaId = criteria.Id
                                                     };
                                      });

            // check the event that has FALSE defaults

            ApiClient.Put($"configuration/rules/workflows/{data.CriteriaId}/events/{data.OffEventId}?insertAfterEventId=null&applyToChildren=false", null);

            var offEvent = ApiClient.Get<WorkflowEventControlModel>($"configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.OffEventId}");
            Assert.IsFalse(offEvent.DueDateCalcSettings.RecalcEventDate);
            Assert.IsFalse(offEvent.DueDateCalcSettings.DoNotCalculateDueDate);

            // check the event that has TRUE defaults

            ApiClient.Put($"configuration/rules/workflows/{data.CriteriaId}/events/{data.OnEventId}?insertAfterEventId=null&applyToChildren=false", null);

            var onEvent = ApiClient.Get<WorkflowEventControlModel>($"configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.OnEventId}");
            Assert.IsTrue(onEvent.DueDateCalcSettings.RecalcEventDate);
            Assert.IsTrue(onEvent.DueDateCalcSettings.DoNotCalculateDueDate);
        }
    }
}
