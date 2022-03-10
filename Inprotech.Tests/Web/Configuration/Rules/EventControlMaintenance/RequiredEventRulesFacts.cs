using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.EventControlMaintenance
{
    public class RequiredEventRulesFacts
    {
        public class ApplyChangesMethod
        {
            [Fact]
            public void AddsAddedRows()
            {
                var f = new RequiredEventRulesFixture();
                var model = new WorkflowEventControlSaveModel();
                var fieldsToUpdate = new EventControlFieldsToUpdate();

                fieldsToUpdate.RequiredEventRulesDelta = new Delta<int>
                {
                    Added = new List<int> {1}
                };

                var validEvent = new ValidEventBuilder().Build();
                f.Subject.ApplyChanges(validEvent, model, fieldsToUpdate);

                Assert.Equal(1, validEvent.RequiredEvents.Count);
                var added = validEvent.RequiredEvents.First();
                Assert.Equal(1, added.RequiredEventId);
            }

            [Fact]
            public void DeletesDeletedRows()
            {
                var f = new RequiredEventRulesFixture();
                var model = new WorkflowEventControlSaveModel();
                var fieldsToUpdate = new EventControlFieldsToUpdate();

                fieldsToUpdate.RequiredEventRulesDelta = new Delta<int>
                {
                    Deleted = new List<int> {1}
                };

                var validEvent = new ValidEventBuilder().Build();
                validEvent.RequiredEvents.Add(new RequiredEventRule(validEvent) {RequiredEventId = 1});

                model.OriginatingCriteriaId = validEvent.CriteriaId;

                f.Subject.ApplyChanges(validEvent, model, fieldsToUpdate);

                Assert.Equal(0, validEvent.RequiredEvents.Count);
            }
        }
    }

    public class RequiredEventRulesFixture : IFixture<RequiredEventRules>
    {
        public RequiredEventRulesFixture()
        {
            WorkflowEventInheritanceService = Substitute.For<IWorkflowEventInheritanceService>();

            Subject = new RequiredEventRules();
        }

        public IWorkflowEventInheritanceService WorkflowEventInheritanceService { get; }
        public RequiredEventRules Subject { get; }
    }
}