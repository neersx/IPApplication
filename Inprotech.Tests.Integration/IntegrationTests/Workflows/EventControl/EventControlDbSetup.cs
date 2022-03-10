using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.EventControl
{
    public class EventControlDbSetup : DbSetup
    {
        public class InheritanceTreeFixture
        {
            public int EventId { get; set; }
            public int CriteriaId { get; set; }
            public ValidEvent CriteriaValidEvent { get; set; }
            public int ChildCriteriaId { get; set; }
            public ValidEvent ChildValidEvent { get; set; }
            public int GrandchildCriteriaId { get; set; }
            public ValidEvent GrandchildValidEvent { get; set; }
            public string Importance { get; set; }

        }

        public InheritanceTreeFixture SetupCriteriaInheritance(ValidEvent basedOnRules = null, Country jurisdiction = null)
        {
            var @event = InsertWithNewId(new Event());
            var criteriaBuilder = new CriteriaBuilder(DbContext) {JurisdictionId = jurisdiction?.Id};

            var criteria = criteriaBuilder.Create("parent");
            ValidEvent criteriaValidEvent;
            if (basedOnRules == null)
            {
                criteriaValidEvent = Insert(new ValidEvent(criteria, @event, "Apple") {NumberOfCyclesAllowed = 1, Inherited = 1});
            }
            else
            {
                basedOnRules.CriteriaId = criteria.Id;
                basedOnRules.EventId = @event.Id;
                basedOnRules.Description = "Apple";
                basedOnRules.NumberOfCyclesAllowed = 1;
                basedOnRules.Inherited = 1;
                criteriaValidEvent = Insert(basedOnRules);
            }

            var child = criteriaBuilder.Create("child", criteria.Id);
            child.ParentCriteriaId = criteria.Id;
            var childValidEvent = new ValidEvent(child, @event);
            childValidEvent.InheritRulesFrom(criteriaValidEvent);
            Insert(childValidEvent);

            var grandchild = criteriaBuilder.Create("grandChild", child.Id);
            grandchild.ParentCriteriaId = child.Id;
            var grandchildValidEvent = new ValidEvent(grandchild, @event);
            grandchildValidEvent.InheritRulesFrom(childValidEvent);
            Insert(grandchildValidEvent);

            var importance = Insert(new Importance {Level = "E2", Description = "E2E"});

            return new InheritanceTreeFixture
            {
                EventId = @event.Id,
                CriteriaId = criteria.Id,
                CriteriaValidEvent = criteriaValidEvent,
                ChildCriteriaId = child.Id,
                ChildValidEvent = childValidEvent,
                GrandchildCriteriaId = grandchild.Id,
                GrandchildValidEvent = grandchildValidEvent,
                Importance = importance.Level
            };
        }

        public class DueDateRespDataFixture
        {
            public int EventId { get; set; }
            public int ParentId { get; set; }
            public int ChildId { get; set; }
            public string Importance { get; set; }
            public int ParentCaseId { get; set; }
            public int ChildCaseId { get; set; }
            public int CaseNameForParent { get; set; }
            public string CaseNameType { get; set; }
            public int NewNameId { get; set; }
        }

        public DueDateRespDataFixture SetupResponsibilityData()
        {
            var controllingAction = new ActionBuilder(DbContext).Create("Controlling Action");
            var @event = InsertWithNewId(new Event {ControllingAction = controllingAction.Code});
            var parent = InsertWithNewId(new Criteria
            {
                Description = Fixture.Prefix("parent"),
                PurposeCode = CriteriaPurposeCodes.EventsAndEntries
            });
            Insert(new ValidEvent(parent, @event, "Apple") {NumberOfCyclesAllowed = 1});

            var child = InsertWithNewId(new Criteria
            {
                Description = Fixture.Prefix("child1"),
                PurposeCode = CriteriaPurposeCodes.EventsAndEntries
            });
            Insert(new ValidEvent(child, @event, "Orange") {NumberOfCyclesAllowed = 1, Inherited = 1});
            Insert(new Inherits {Criteria = child, FromCriteria = parent});

            var importance = Insert(new Importance {Level = "E2", Description = "E2E"});

            var parentCase = new CaseBuilder(DbContext).Create("Case 1");
            Insert(new OpenAction
            {
                CriteriaId = parent.Id,
                CaseId = parentCase.Id,
                ActionId = controllingAction.Code,
                Cycle = 1,
                PoliceEvents = 1
            });
            Insert(new CaseEvent(parentCase.Id, @event.Id, 1) {IsOccurredFlag = 0});

            var childCase = new CaseBuilder(DbContext).Create("Case 2");
            Insert(new OpenAction
            {
                CriteriaId = child.Id,
                CaseId = childCase.Id,
                ActionId = controllingAction.Code,
                PoliceEvents = 1
            });
            Insert(new CaseEvent(childCase.Id, @event.Id, 1) {IsOccurredFlag = 0});

            var nameType = new NameTypeBuilder(DbContext).Create();
            var nameBuilder = new NameBuilder(DbContext);

            // Set up name1 to be lowest sequence no. CaseName for case
            var name1 = nameBuilder.CreateStaff("Parent");
            Insert(new CaseName(parentCase, nameType, nameBuilder.CreateStaff("Random"), 1));
            Insert(new CaseName(parentCase, nameType, name1, 0));

            var newName = nameBuilder.CreateStaff("Different");

            return new DueDateRespDataFixture
            {
                EventId = @event.Id,
                ParentId = parent.Id,
                ChildId = child.Id,
                Importance = importance.Level,
                ParentCaseId = parentCase.Id,
                ChildCaseId = childCase.Id,
                CaseNameForParent = name1.Id,
                CaseNameType = nameType.NameTypeCode,
                NewNameId = newName.Id
            };
        }
    }
}
