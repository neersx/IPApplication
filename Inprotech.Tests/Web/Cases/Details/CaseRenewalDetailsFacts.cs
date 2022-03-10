using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.StandingInstructions;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseRenewalDetailsFacts : FactBase
    {
        [Fact]
        public async Task ReturnsRenewalsBasicDetails()
        {
            const int caseId = 100;
            const int screenCriteriaId = 1234;
            const int renewalTypeTableCode = 10;
            const int extendedYears = 99;
            const int renewalYear = 7;
            const string renewalTypeDesc = "e2e Renewal Type";
            const string stopPayReasonUserCode = "R";
            const string stopPayReasonDescription = "stop pay freeson";
            const string renewalNotes = "R notes";

            var nextRenewalDate = Fixture.Monday;

            var f = new CaseRenewalDetailsFixture()
                    .WithRenewalTypeTableCode(renewalTypeTableCode, renewalTypeDesc)
                    .WithRenewalDates(nextRenewalDate)
                    .WithCaseDetails(caseId, extendedYears, renewalTypeTableCode, stopPayReasonUserCode, renewalNotes)
                    .WithStopPayReasonTableCode(stopPayReasonUserCode, stopPayReasonDescription);

            var result = await f.Subject.GetRenewalDetails(caseId, screenCriteriaId);

            f.NextRenewalDatesResolver
             .Received(1)
             .Resolve(caseId)
             .IgnoreAwaitForNSubstituteAssertion();

            Assert.Equal(renewalTypeDesc, result.RenewalType);
            Assert.Equal(extendedYears, result.ExtendedRenewalYears);
            Assert.Equal(nextRenewalDate, result.NextRenewalDate);
            Assert.Equal(renewalYear, result.RenewalYear);
            Assert.Equal(stopPayReasonDescription, result.ReasonToStopPay);
            Assert.Equal(renewalNotes, result.RenewalNotes);
        }
        
        [Fact]
        public async Task ReturnsCpaRenewalData()
        {
            const int caseId = 100;
            const int renewalTypeTableCode = 10;
            const int extendedYears = 99;
            var extraDate = DateTime.Now.Date.AddMonths(-19);
            var cpaDate = DateTime.Now.Date.AddMonths(-30);
            var portfolioDate = DateTime.Now.Date.AddMonths(-40);

            var f = new CaseRenewalDetailsFixture()
                    .WithCaseDetails(caseId, extendedYears, renewalTypeTableCode, "11", "TestNotes")
                    .WithCpaRenewalData(caseId, extraDate, cpaDate, portfolioDate);

            var result = await f.Subject.GetRenewalDetails(caseId, caseId);
            
            Assert.Equal(extraDate, result.LastExtracted);
            Assert.Equal(cpaDate, result.LastCpaEvent);
            Assert.Equal(portfolioDate, result.PortfolioDate);
            Assert.Equal(2, result.LastExtractedNo);
        }
    }

    public class RenewalDetailsRelevantDatesFacts : FactBase
    {
        [Fact]
        public async Task ReturnDoNotDisplayRelevantDatesIfSiteControlNotSet()
        {
            const int caseId = 100;
            const int screenCriteriaId = 1234;
            var f = new CaseRenewalDetailsFixture()
                    .WithCaseDetails(caseId)
                    .WithRenewalDates(Fixture.Monday);

            var r = await f.Subject.GetRenewalDetails(caseId, screenCriteriaId);

            Assert.Empty(r.RelevantDates);
        }

        [Fact]
        public async Task ReturnRenewalNamesIfSiteControlNotSet()
        {
            const int caseId = 100;
            const int screenCriteriaId = 1234;
            var f = new CaseRenewalDetailsFixture()
                    .WithCaseDetails(caseId)
                    .WithRenewalDates(Fixture.Monday)
                    .WithRenewalNameTypeOptional(true)
                    .WithRenewalNames();

            var r = await f.Subject.GetRenewalDetails(caseId, screenCriteriaId);

            Assert.Equal(2, r.RenewalNames.Count());
        }

        [Fact]
        public async Task ReturnRenewalNamesIfSiteControlSet()
        {
            const int caseId = 100;
            const int screenCriteriaId = 1234;
            var f = new CaseRenewalDetailsFixture()
                    .WithCaseDetails(caseId)
                    .WithRenewalDates(Fixture.Monday)
                    .WithRenewalNameTypeOptional(false)
                    .WithRenewalNames();

            var r = await f.Subject.GetRenewalDetails(caseId, screenCriteriaId);

            Assert.Equal(2, r.RenewalNames.Count());
        }

        [Fact]
        public async Task ReturnDoNotDisplayRelevantDatesIfCriteriaNoNotFound()
        {
            const int caseId = 100;
            const int screenCriteriaId = 1234;
            var f = new CaseRenewalDetailsFixture()
                    .WithCaseDetails(caseId)
                    .WithRenewalDates(Fixture.Monday)
                    .WithRenewalDisplayActionCode("A");

            var r = await f.Subject.GetRenewalDetails(caseId, screenCriteriaId);

            Assert.Empty(r.RelevantDates);
        }

        [Fact]
        public async Task ReturnsAllRelevantDates()
        {
            const int caseId = 100;
            const int screenCriteriaId = 1234;
            const int criteriaNo = 10;
            const int eventNo1 = 10;
            const int eventNo2 = 11;
            var action = Fixture.RandomString(2);

            var f = new CaseRenewalDetailsFixture()
                    .WithCaseDetails(caseId)
                    .WithRenewalDates(Fixture.Monday)
                    .WithRenewalDisplayActionCode(action)
                    .WithRenewalDisplayActionCodeCriteria(criteriaNo)
                    .WithEventsAndInstructions(caseId, criteriaNo, action, eventNo1, eventNo2);

            var r = await f.Subject.GetRenewalDetails(caseId, screenCriteriaId);

            Assert.NotEmpty(r.RelevantDates);
            Assert.Equal(2, r.RelevantDates.Count());

            var event1 = f.DbContext.Set<CaseEvent>().Single(_ => _.EventNo == eventNo1);
            var eventText1 = f.DbContext.Set<ValidEvent>().Single(_ => _.EventId == eventNo1).Description;
            var resultEvent1 = r.RelevantDates.SingleOrDefault(_ => _.EventNo == eventNo1);

            Assert.NotNull(resultEvent1);
            Assert.Equal(event1.EventDate, resultEvent1.EventDate);
            Assert.Equal(eventText1, resultEvent1.EventDescription);
            Assert.True(resultEvent1.IsOccurred);

            var event2 = f.DbContext.Set<CaseEvent>().Single(_ => _.EventNo == eventNo2);
            var resultEvent2 = r.RelevantDates.SingleOrDefault(_ => _.EventNo == eventNo2);

            Assert.NotNull(resultEvent2);
            Assert.Equal(event2.EventDueDate, resultEvent2.EventDate);
            Assert.False(resultEvent2.IsOccurred);
        }

        [Fact]
        public async Task ReturnsRelevantDatesFilteredOutForExternalUsers()
        {
            const int caseId = 100;
            const int screenCriteriaId = 1234;
            const int criteriaNo = 10;
            const int eventNo1 = 10;
            const int eventNo2 = 11;
            var action = Fixture.RandomString(2);

            var f = new CaseRenewalDetailsFixture()
                    .WithCaseDetails(caseId)
                    .WithRenewalDates(Fixture.Monday)
                    .WithRenewalDisplayActionCode(action)
                    .WithRenewalDisplayActionCodeCriteria(criteriaNo)
                    .WithEventsAndInstructions(caseId, criteriaNo, action, eventNo1, eventNo2)
                    .WithEventFilteredForExternalUsers(eventNo1);

            var r = await f.Subject.GetRenewalDetails(caseId, screenCriteriaId);

            Assert.Equal(1, r.RelevantDates.Count());
            Assert.NotNull(r.RelevantDates.SingleOrDefault(_ => _.EventNo == eventNo1));
            Assert.Null(r.RelevantDates.SingleOrDefault(_ => _.EventNo == eventNo2));
        }

        [Fact]
        public async Task ReturnsNextRenewalDateAfterCalculation()
        {
            const int caseId = 100;
            const int screenCriteriaId = 1234;
            const int criteriaNo = 10;
            const int eventNo1 = 11;
            const int eventNo2 = (int) KnownEvents.NextRenewalDate;

            var action = Fixture.RandomString(2);
            var nextRenewalDate = Fixture.PastDate();

            var f = new CaseRenewalDetailsFixture()
                    .WithCaseDetails(caseId)
                    .WithRenewalDates(nextRenewalDate)
                    .WithRenewalDisplayActionCode(action)
                    .WithRenewalDisplayActionCodeCriteria(criteriaNo)
                    .WithEventsAndInstructions(caseId, criteriaNo, action, eventNo1, eventNo2);

            var r = await f.Subject.GetRenewalDetails(caseId, screenCriteriaId);

            var renewalDate = r.RelevantDates.SingleOrDefault(_ => _.EventNo == eventNo2);
            Assert.NotNull(renewalDate);
            Assert.Equal(nextRenewalDate, renewalDate.EventDate);
        }
        
    }

    public class RenewalDetailsStandingInstructions
    {
        const int CaseId = 100;
        const int screenCriteriaId = 1234;
        const int CriteriaNo = 10;
        const int EventNo1 = 10;
        const int EventNo2 = 11;
        const string InstructionTypeCode = "A";
        readonly string _action = Fixture.RandomString(2);

        [Fact]
        public async Task ReturnsNoResultsIfNoCaseInstructions()
        {
            var f = new CaseRenewalDetailsFixture()
                    .WithCaseDetails(CaseId)
                    .WithEventsAndInstructions(CaseId, CriteriaNo, _action, EventNo1, EventNo2)
                    .WithCaseStandingInstructions(new StandingInstruction[] { });

            var result = await f.Subject.GetRenewalDetails(CaseId, screenCriteriaId);

            Assert.Empty(result.StandingInstructions);
        }

        [Fact]
        public async Task ReturnsNoResultsWithoutRelevantConfiguration()
        {
            var f = new CaseRenewalDetailsFixture()
                    .WithCaseDetails(CaseId)
                    .WithCaseStandingInstructions(new[] {new StandingInstruction {CaseId = CaseId, InstructionTypeCode = InstructionTypeCode, Description = Fixture.RandomString(10)}});

            var result = await f.Subject.GetRenewalDetails(CaseId, screenCriteriaId);

            Assert.Empty(result.StandingInstructions);
        }

        [Fact]
        public async Task ReturnsResultsWithInstuctions()
        {
            var instructionDescription = Fixture.RandomString(10);
            var instructionTypeDescription = Fixture.RandomString(10);
            var f = new CaseRenewalDetailsFixture()
                    .WithCaseDetails(CaseId)
                    .WithEventsAndInstructions(CaseId, CriteriaNo, _action, EventNo1, EventNo2)
                    .WithCaseStandingInstructions(new[] {new StandingInstruction {CaseId = CaseId, InstructionTypeCode = InstructionTypeCode, Description = instructionDescription, InstructionTypeDesc = instructionTypeDescription}})
                    .WithExternalUserInstructionsRestrictionFor(InstructionTypeCode);

            var result = await f.Subject.GetRenewalDetails(CaseId, screenCriteriaId);

            Assert.NotEmpty(result.StandingInstructions);

            var firstInstruction = result.StandingInstructions.FirstOrDefault();
            Assert.NotNull(firstInstruction);
            Assert.Equal(InstructionTypeCode, firstInstruction.InstructionType);
            Assert.Equal(instructionDescription, firstInstruction.Instruction);
            Assert.Equal(instructionTypeDescription, firstInstruction.InstructionTypeDescription);
        }

        [Fact]
        public async Task ReturnsInstructionsForExternalUsers()
        {
            var instructionDescription = Fixture.RandomString(10);
            var f = new CaseRenewalDetailsFixture()
                    .WithCaseDetails(CaseId)
                    .WithEventsAndInstructions(CaseId, CriteriaNo, _action, EventNo1, EventNo2)
                    .WithCaseStandingInstructions(new[] {new StandingInstruction {CaseId = CaseId, InstructionTypeCode = InstructionTypeCode, Description = instructionDescription}})
                    .WithExternalUserInstructionsRestrictionFor("A");

            var result = await f.Subject.GetRenewalDetails(CaseId, screenCriteriaId);

            Assert.NotEmpty(result.StandingInstructions);

            var firstInstruction = result.StandingInstructions.FirstOrDefault();
            Assert.NotNull(firstInstruction);
            Assert.Equal(InstructionTypeCode, firstInstruction.InstructionType);
        }

        [Fact]
        public async Task ReturnsRestrictedInstructionsForExternalUsers()
        {
            var instructionDescription = Fixture.RandomString(10);
            var f = new CaseRenewalDetailsFixture()
                    .WithCaseDetails(CaseId)
                    .WithEventsAndInstructions(CaseId, CriteriaNo, _action, EventNo1, EventNo2)
                    .WithCaseStandingInstructions(new[] {new StandingInstruction {CaseId = CaseId, InstructionTypeCode = InstructionTypeCode, Description = instructionDescription}})
                    .WithExternalUserInstructionsRestrictionFor("B");

            var result = await f.Subject.GetRenewalDetails(CaseId, screenCriteriaId);

            Assert.Empty(result.StandingInstructions);
        }
    }

    public class RenewDetailsIpPlatformRenewLink
    {
        [Fact]
        public async Task ReturnsNUllIfDocItemNotFoundOrExceptionThrown()
        {
            const int caseId = 100;
            const int screenCriteriaId = 1234;
            var f = new CaseRenewalDetailsFixture().WithCaseDetails(caseId);
  
            f.DocItemRunner
             .Run(Arg.Any<string>(), Arg.Any<Dictionary<string, object>>())
             .ThrowsForAnyArgs(new ArgumentException());

            var r = await f.Subject.GetRenewalDetails(caseId, screenCriteriaId);

            Assert.Null(r.IpplatformRenewLink);
        }

        [Fact]
        public async Task ReturnsNUllIfDocItemReturnsNUll()
        {
            const int caseId = 100;
            var ds = GetDataSetFor(null);
            const int screenCriteriaId = 1234;
            var f = new CaseRenewalDetailsFixture().WithCaseDetails(caseId);

            f.DocItemRunner
             .Run(Arg.Any<string>(), Arg.Any<Dictionary<string, object>>())
             .Returns(ds);

            var r = await f.Subject.GetRenewalDetails(caseId, screenCriteriaId);

            Assert.Null(r.IpplatformRenewLink);
        }

        [Fact]
        public async Task ReturnsLinkReturnedByDocItem()
        {
            const int caseId = 100;
            const string link = "www.google.com";
            var ds = GetDataSetFor(link);
            const int screenCriteriaId = 1234;
            var f = new CaseRenewalDetailsFixture().WithCaseDetails(caseId);

            f.DocItemRunner
             .Run(Arg.Any<string>(), Arg.Any<Dictionary<string, object>>())
             .Returns(ds);

            var r = await f.Subject.GetRenewalDetails(caseId, screenCriteriaId);

            Assert.Equal(link, r.IpplatformRenewLink);
        }

        static DataSet GetDataSetFor(string link)
        {
            var ds = new DataSet();
            var dt = ds.Tables.Add();
            dt.Columns.Add("link", typeof(string));
            dt.Rows.Add(link);

            return ds;
        }
    }

    public class CaseRenewalDetailsFixture : IFixture<ICaseRenewalDetails>
    {
        readonly Dictionary<string, int?> _integerSiteControls = new Dictionary<string, int?>
        {
            { SiteControls.CPADate_Start, null },
            { SiteControls.CPADate_Stop, null }
        };

        readonly Dictionary<string, bool?> _booleanSiteControls = new Dictionary<string, bool?>
        {
            { SiteControls.ClientsUnawareofCPA, null },
            { SiteControls.RenewalNameTypeOptional, null }
        };

        public CaseRenewalDetailsFixture()
        {
            NextRenewalDatesResolver = Substitute.For<INextRenewalDatesResolver>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            DbContext = new InMemoryDbContext();
            SecurityContext = Substitute.For<ISecurityContext>();
            SecurityContext.User.Returns(new User(Fixture.String(), false));
            CriteriaReader = Substitute.For<ICriteriaReader>();
            UserFilteredTypes = Substitute.For<IUserFilteredTypes>();
            CaseStandingInstructionNameType = Substitute.For<ICaseStandingInstructions>();
            CaseViewNamesProvider = Substitute.For<ICaseViewNamesProvider>();
            DocItemRunner = Substitute.For<IDocItemRunner>();

            PreferredCultureResolver.Resolve().Returns(string.Empty);

            NextRenewalDatesResolver.Resolve(Arg.Any<int>())
                                    .Returns(new RenewalDates());

            SiteControlReader.ReadMany<int?>(SiteControls.CPADate_Start, SiteControls.CPADate_Stop)
                             .Returns(_integerSiteControls);

            SiteControlReader.ReadMany<bool?>(SiteControls.ClientsUnawareofCPA, SiteControls.RenewalNameTypeOptional)
                             .Returns(_booleanSiteControls);

            Subject = new CaseRenewalDetails(DbContext, NextRenewalDatesResolver, SiteControlReader, PreferredCultureResolver, SecurityContext, CriteriaReader, CaseStandingInstructionNameType, CaseViewNamesProvider, UserFilteredTypes, DocItemRunner);
        }

        public CaseRenewalDetailsFixture WithRenewalDates(DateTime nextRenewalDate, int renewalYear = 7)
        {
            NextRenewalDatesResolver.Resolve(Arg.Any<int>())
                                    .Returns(new RenewalDates
                                    {
                                        AgeOfCase = (short) renewalYear,
                                        NextRenewalDate = nextRenewalDate,
                                    });

            return this;
        }

        public CaseRenewalDetailsFixture WithRenewalTypeTableCode(int tableCode, string desc)
        {
            new TableTypeBuilder(DbContext).For(TableTypes.RenewalType)
                                           .Build()
                                           .In(DbContext);

            new TableCodeBuilder {TableCode = tableCode, Description = desc}
                .For(TableTypes.RenewalType)
                .Build()
                .In(DbContext);

            return this;
        }

        public CaseRenewalDetailsFixture WithCaseDetails(int caseId, int extendedRenewalYears = 10, int renewalType = 1, string stopPayReasonUserCode = "ABCD", string renewalNotes = "notes")
        {
            _case = new CaseBuilder
                    {
                        Property = new CasePropertyBuilder
                        {
                            RenewalType = renewalType,
                        }.Build().In(DbContext)
                    }
                    .BuildWithId(caseId)
                    .In(DbContext);

            _case.ExtendedRenewals = extendedRenewalYears;
            _case.StopPayReason = stopPayReasonUserCode;
            _case.Property.RenewalNotes = renewalNotes;
            DbContext.SaveChanges();

            return this;
        }

        public CaseRenewalDetailsFixture WithCpaPayStartStopEvents(int? cpaStartPayEventNo, int? cpaStopPayEventNo)
        {
            _integerSiteControls[SiteControls.CPADate_Start] = cpaStartPayEventNo;
            _integerSiteControls[SiteControls.CPADate_Stop] = cpaStopPayEventNo;
            return this;
        }

        public CaseRenewalDetailsFixture WithStopPayReasonTableCode(string stopPayReasonUserCode, string stopPayReasonUserDescription)
        {
            new TableTypeBuilder(DbContext).For(TableTypes.CpaStopPayReason68)
                                           .Build()
                                           .In(DbContext);

            new TableCodeBuilder {TableCode = 11, Description = stopPayReasonUserDescription, UserCode = stopPayReasonUserCode}
                .For(TableTypes.CpaStopPayReason68)
                .Build()
                .In(DbContext);

            return this;
        }

        public CaseRenewalDetailsFixture WithCpaRenewalData(int caseId, DateTime extract, DateTime cpa, DateTime portfolio)
        {
            new CpaSend {CaseId = caseId, BatchNo = 1, BatchDate = Fixture.PastDate()}.In(DbContext);
            new CpaSend {CaseId = caseId, BatchNo = 2, BatchDate = extract}.In(DbContext);
            new CpaEvent {CaseId = caseId, CefNo = Fixture.Integer(), RenewalEventDate = Fixture.PastDate()}.In(DbContext);
            new CpaEvent {CaseId = caseId, CefNo = Fixture.Integer(), RenewalEventDate = cpa}.In(DbContext);
            new CpaPortfolio {CaseId = caseId, StatusIndicator = "L", DateOfPortfolioList = portfolio}.In(DbContext);
            return this;
        }

        public CaseRenewalDetailsFixture WithRenewalDisplayActionCode(string action)
        {
            SiteControlReader.Read<string>(SiteControls.RenewalDisplayActionCode).Returns(action);

            return this;
        }

        public CaseRenewalDetailsFixture WithRenewalDisplayActionCodeCriteria(int criteriano)
        {
            CriteriaReader.TryGetEventControl(Arg.Any<int>(), Arg.Any<string>(), out var _).ReturnsForAnyArgs(info =>
            {
                info[2] = criteriano;
                return true;
            });

            return this;
        }

        public CaseRenewalDetailsFixture WithEventsAndInstructions(int caseId, int criteriaNo, string actionName, int eventNo1, int eventNo2, string instructionTypeCode = "A", bool allowedExternalUser = false)
        {

            var instructionType = new InstructionTypeBuilder {Code = instructionTypeCode, Description = Fixture.RandomString(50)}
                                  .Build()
                                  .In(DbContext);

            new Instruction {InstructionType = instructionType, InstructionTypeCode = instructionType.Code, Description = Fixture.RandomString(10)}
                .In(DbContext);

            var action = new ActionBuilder {ActionType = 1, Id = Fixture.String("renew"), Name = actionName}
                         .Build()
                         .In(DbContext);

            var criteria = new CriteriaBuilder {Id = criteriaNo, Action = action}
                           .Build()
                           .In(DbContext);

            var event1 = new EventBuilder {Id = eventNo1, Description = Fixture.RandomString(40), ControllingAction = actionName}
                         .Build()
                         .In(DbContext);

            var event2 = new EventBuilder {Id = eventNo2, Description = Fixture.RandomString(40), ControllingAction = actionName}
                         .Build()
                         .In(DbContext);

            var ve1 = new ValidEventBuilder
                {
                    Criteria = criteria,
                    Event = event1,
                    Description = Fixture.RandomString(40),
                    InstructionType = instructionType.Code
                }.Build()
                 .In(DbContext);

            var ve2 = new ValidEventBuilder
                {
                    Criteria = criteria,
                    Event = event2,
                    Description = Fixture.RandomString(40),
                    InstructionType = instructionType.Code
                }.Build()
                 .In(DbContext);

            if (allowedExternalUser)
            {
                new FilteredUserEvent
                {
                    EventNo = ve1.Event.Id,
                    EventCode = ve1.Event.Code,
                    EventDescription = ve1.Event.Description,
                    ImportanceLevel = ve1.Event.ImportanceLevel,
                    ControllingAction = ve1.Event.ControllingAction,
                    Definition = ve1.Event.Notes,
                    NumCyclesAllowed = ve1.Event.NumberOfCyclesAllowed
                }.In(DbContext);

                new FilteredUserEvent
                {
                    EventNo = ve2.Event.Id,
                    EventCode = ve2.Event.Code,
                    EventDescription = ve2.Event.Description,
                    ImportanceLevel = ve2.Event.ImportanceLevel,
                    ControllingAction = ve2.Event.ControllingAction,
                    Definition = ve2.Event.Notes,
                    NumCyclesAllowed = ve2.Event.NumberOfCyclesAllowed
                }.In(DbContext);
            }

            _case.CaseEvents.Add(new CaseEventBuilder {CaseId = caseId, CreatedByCriteriaKey = criteriaNo, CreatedByActionKey = action.Code, Cycle = 1, Event = event1, EventDate = DateTime.MinValue}
                                 .Build()
                                 .In(DbContext));

            _case.CaseEvents.Add(new CaseEventBuilder {CaseId = caseId, CreatedByCriteriaKey = criteriaNo, CreatedByActionKey = action.Code, Cycle = 1, Event = event2, DueDate = DateTime.MaxValue}
                                 .Build()
                                 .In(DbContext));

            return this;
        }

        public CaseRenewalDetailsFixture WithEventFilteredForExternalUsers(int eventNo)
        {
            SecurityContext.User.Returns(new User(Fixture.String(), true).In(DbContext));

            new FilteredUserEvent
            {
                EventNo = eventNo
            }.In(DbContext);

            return this;
        }

        public CaseRenewalDetailsFixture WithCaseStandingInstructions(StandingInstruction[] instructions)
        {
            CaseStandingInstructionNameType.GetStandingInstructions(Arg.Any<int>())
                                           .Returns(instructions);
            return this;
        }

        public CaseRenewalDetailsFixture WithExternalUserInstructionsRestrictionFor(string instructionTypeCode = "Z")
        {
            var instructionType = DbContext.Set<InstructionType>().SingleOrDefault(_ => _.Code == instructionTypeCode);

            UserFilteredTypes.InstructionTypes()
                             .ReturnsForAnyArgs(instructionType != null ? new[] {instructionType}.AsQueryable() : new InstructionType[] { }.AsQueryable());

            return this;
        }

        public CaseRenewalDetailsFixture WithRenewalNameTypeOptional(bool value)
        {
            _booleanSiteControls[SiteControls.RenewalNameTypeOptional] = value;

            return this;
        }

        public CaseRenewalDetailsFixture WithRenewalNames()
        {
            CaseViewNamesProvider.GetNames(Arg.Any<int>(), Arg.Any<string[]>(), Arg.Any<int>())
                                  .Returns(new[]
                                  {
                                      new CaseViewName {TypeId = "R", Attention = "Abc"},
                                      new CaseViewName {TypeId = "Z", Attention = "xyz"},
                                      new CaseViewName {TypeId = "I", Attention = "Def"}
                                  });
            return this;
        }

        public ICaseRenewalDetails Subject { get; }
        public ISiteControlReader SiteControlReader { get; }
        public INextRenewalDatesResolver NextRenewalDatesResolver { get; }
        public IPreferredCultureResolver PreferredCultureResolver { get; }
        public ISecurityContext SecurityContext { get; }
        public ICriteriaReader CriteriaReader { get; }
        public InMemoryDbContext DbContext { get; }
        public ICaseStandingInstructions CaseStandingInstructionNameType { get; }
        public IUserFilteredTypes UserFilteredTypes { get; }
        public IDocItemRunner DocItemRunner { get; }
        Case _case;
        public ICaseViewNamesProvider CaseViewNamesProvider { get; }
    }
}