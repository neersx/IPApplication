using System;
using System.Globalization;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Components.Configuration.Rules;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowSearchFacts
    {
        public class SearchMethod : FactBase
        {
            [Fact]
            public void SearchesByCriteriaIds()
            {
                var f = new WorkflowSearchFixture(Db);

                int[] all = {1, 2, 3};

                f.Subject.Search(all);

                f.DbContext.Received(1)
                 .SqlQuery<WorkflowSearchListItem>(Arg.Any<string>(), Arg.Any<int>(),
                                                   Arg.Any<string>(),
                                                   CriteriaPurposeCodes.EventsAndEntries, //  @psPurposeCode
                                                   Arg.Is<string>(s => s == null), //  @pnCaseOfficeID
                                                   Arg.Is<string>(s => s == null), //  @psCaseType
                                                   Arg.Is<string>(s => s == null), //  @psAction
                                                   Arg.Is<string>(s => s == null), //  @psPropertyType
                                                   Arg.Is<string>(s => s == null), //  @psCountryCode
                                                   Arg.Is<string>(s => s == null), //  @psCaseCategory
                                                   Arg.Is<string>(s => s == null), //  @psSubType
                                                   Arg.Is<string>(s => s == null), //  @psBasis
                                                   Arg.Is<string>(s => s == null), //  @pnLocalClientFlag
                                                   Arg.Is<string>(s => s == null), //  @pdtDateOfAct
                                                   Arg.Is<string>(s => s == null), //  @pnRuleInUse
                                                   Arg.Is<string>(s => s == null), //  @pbExactMatch        
                                                   Arg.Is<string>(s => s == null), //  @pbUserDefinedRule
                                                   "1,2,3",
                                                   Arg.Is<string>(s => s == null), // @pnEventNo
                                                   Arg.Is<string>(s => s == null) //  @pnTableCode
                                                  );
            }

            [Fact]
            public void UsesTheCorrectFilters()
            {
                var f = new WorkflowSearchFixture(Db);

                var filter = new SearchCriteria
                {
                    Action = Fixture.String("Action"),
                    ApplyTo = ClientFilterOptions.Na,
                    Basis = Fixture.String("Basis"),
                    CaseCategory = Fixture.String("CaseCategory"),
                    CaseType = Fixture.String("CaseType"),
                    DateOfLaw = Fixture.PastDate().ToString(CultureInfo.InvariantCulture),
                    IncludeCriteriaNotInUse = true,
                    IncludeProtectedCriteria = false,
                    Office = Fixture.Integer(),
                    Jurisdiction = Fixture.String("Jurisdiction"),
                    PropertyType = Fixture.String("PropertyType"),
                    SubType = Fixture.String("SubType"),
                    MatchType = CriteriaMatchOptions.ExactMatch,
                    Event = Fixture.Integer(),
                    RenewalType = Fixture.Integer()
                };

                f.Subject.Search(filter);

                f.DbContext.Received(1)
                 .SqlQuery<WorkflowSearchListItem>(Arg.Any<string>(), Arg.Any<int>(),
                                                   Arg.Any<string>(),
                                                   CriteriaPurposeCodes.EventsAndEntries, //  @psPurposeCode
                                                   filter.Office, //  @pnCaseOfficeID
                                                   filter.CaseType, //  @psCaseType
                                                   filter.Action, //  @psAction
                                                   filter.PropertyType, //  @psPropertyType
                                                   filter.Jurisdiction, //  @psCountryCode
                                                   filter.CaseCategory, //  @psCaseCategory
                                                   filter.SubType, //  @psSubType
                                                   filter.Basis, //  @psBasis
                                                   Arg.Any<string>(), //  @pnLocalClientFlag
                                                   Arg.Any<DateTime>(), //  @pdtDateOfAct
                                                   Arg.Any<string>(), //  @pnRuleInUse
                                                   true, //  @pbExactMatch      
                                                   true, //  @pbUserDefinedRule
                                                   Arg.Is<string>(s => s == null), // Criteria numbers are null
                                                   filter.Event, // @pnEventNo
                                                   filter.RenewalType // @pnTableCode
                                                  );
            }
        }

        public class SearchForEventsReferencedInMethod : FactBase
        {
            [Fact]
            public void CallsProcWithCorrectParams()
            {
                var criteriaId = Fixture.Integer();
                var eventId = Fixture.Integer();
                var f = new WorkflowSearchFixture(Db);
                f.Subject.SearchForEventReferencedInCriteria(criteriaId, eventId);

                f.DbContext.Received(1).SqlQuery<WorkflowEventReferenceListItem>(Arg.Is<string>(s => s.Contains("ipw_WorkflowEventReferenceSearch")), criteriaId, eventId);
            }
        }

        public class WorkflowSearchFixture : IFixture<WorkflowSearch>
        {
            public WorkflowSearchFixture(InMemoryDbContext db)
            {
                var securityContext = Substitute.For<ISecurityContext>();
                var culture = Substitute.For<IPreferredCultureResolver>();

                securityContext.User.ReturnsForAnyArgs(new UserBuilder(db).Build());

                DbContext = Substitute.For<IDbContext>();

                Subject = new WorkflowSearch(DbContext, securityContext, culture);
            }

            public IDbContext DbContext { get; }
            public WorkflowSearch Subject { get; }
        }
    }
}