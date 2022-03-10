using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail.CriteriaDetailEntry
{
    internal class CriteriaDetailInheritenceFlagsDbSetup : CriteriaDetailDbSetup
    {
        public ScenarioData SetUp(string criteriaDescription = null)
        {
            if (criteriaDescription == null)
            {
                criteriaDescription = CriteriaDescription;
            }

            var criteria = AddCriteria(criteriaDescription);
            var child = AddCriteria(ChildCriteriaDescription, criteria.Id);

            Insert(new Inherits(child.Id, criteria.Id));

            var existingEvent = AddEvent(ExistingEvent, true);
            var existingEvent2 = AddEvent(ExistingEvent2);

            AddEvent(EventToBeAdded);
            AddEvent(EventToBeAdded2);

            var validEvent = AddValidEvent(criteria, existingEvent);

            AddValidEvent(criteria, existingEvent2);
            AddValidEvent(child, existingEvent, true, criteria.Id, existingEvent.Id);

            var parentTask = AddDataEntryTask(criteria, "Data Entry Task");
            AddDataEntryTask(child, "Data Entry Task", true, parentTask.ParentCriteriaId, parentTask.ParentEntryId);

            var newCase = new CaseBuilder(DbContext).Create(Fixture.Prefix());
            Insert(new CaseEvent(newCase.Id, existingEvent.Id, 1));

            var action = Insert(new Action(ActionDescription, id: "e2"));
            Insert(new OpenAction(action, newCase, 1, null, criteria, true));

            return new ScenarioData
            {
                Criteria = criteria,
                CriteriaId = criteria.Id,
                ChildCriteria = child,
                ChildCriteriaId = child.Id,
                ValidEventId = validEvent.EventId,
                EventId = existingEvent.Id,
                EventName = existingEvent.Description,
                EventId2 = existingEvent2.Id,
                ExistingEvent = existingEvent,
                CaseTypeName = newCase.Type.Name,
                PropertyTypeName = newCase.PropertyType.Name,
                ActionId = criteria.ActionId,
                SecondEventId = existingEvent2.Id
            };
        }

        public Criteria AddCriteriaWithEntryInheritance()
        {
            var parentCriteria = AddCriteria(CriteriaDescription);
            var criteria = AddCriteria(ChildCriteriaDescription);

            Insert(new Inherits(criteria.Id, parentCriteria.Id));

            var entryPrefix = Fixture.Prefix("entry");
            var fullyInheritedEvent = entryPrefix + "1";
            var partiallyInheritedEvent = entryPrefix + "2";
            var notInheritedEvent = entryPrefix + "3";

            var pFullyInheritedValidEvent = AddDataEntryTask(parentCriteria, fullyInheritedEvent);
            var pPartiallyInheritedValidEvent = AddDataEntryTask(parentCriteria, partiallyInheritedEvent);
            var pNotInheritedValidEvent = AddDataEntryTask(parentCriteria, notInheritedEvent);

            var cFullyInheritedValidEvent = AddDataEntryTask(criteria, fullyInheritedEvent, true, parentCriteria.Id, pFullyInheritedValidEvent.Id);
            var cPartiallyInheritedValidEvent = AddDataEntryTask(criteria, partiallyInheritedEvent, true, parentCriteria.Id, pPartiallyInheritedValidEvent.Id);
            var cNotInheritedValidEvent = AddDataEntryTask(criteria, notInheritedEvent, false, parentCriteria.Id, pNotInheritedValidEvent.Id);

            AddAvailableEvent(pFullyInheritedValidEvent);
            AddAvailableEvent(pPartiallyInheritedValidEvent);
            AddAvailableEvent(pPartiallyInheritedValidEvent);
            AddAvailableEvent(pNotInheritedValidEvent);

            AddAvailableEvent(cFullyInheritedValidEvent, true);
            AddAvailableEvent(cPartiallyInheritedValidEvent, true);
            AddAvailableEvent(cNotInheritedValidEvent);

            return criteria;
        }
    }
}