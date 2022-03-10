using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Cases.Screens;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Screens
{
    public class CaseViewSectionResolverFacts : FactBase
    {
        public CaseViewSectionResolverFacts()
        {
            var criteria = new CriteriaBuilder().Build().In(Db);
            criteria.ProgramId = _programId;
            _screenCriteriaId = criteria.Id;

            _caseViewWindowControl = new WindowControl(criteria.Id, "CaseDetails").In(Db);
        }

        public const string CaseViewScreenControl = "CaseView.ScreenControl";

        readonly ICriteriaReader _criteriaReader = Substitute.For<ICriteriaReader>();
        readonly ICaseViewFieldMapper _caseViewFieldMapper = Substitute.For<ICaseViewFieldMapper>();
        readonly ISubjectSecurityProvider _subjectSecurity = Substitute.For<ISubjectSecurityProvider>();
        readonly int _screenCriteriaId;
        readonly string _culture = Fixture.String();
        readonly int _caseId = Fixture.Integer();
        readonly string _programId = Fixture.String();
        readonly WindowControl _caseViewWindowControl;

        ICaseViewSectionsResolver CreateSubject(User user = null)
        {
            var theUser = user ?? new User(Fixture.String(), false).In(Db);
            var securityContext = Substitute.For<ISecurityContext>();
            securityContext.User.Returns(theUser);

            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            preferredCultureResolver.Resolve().Returns(_culture);

            _caseViewFieldMapper.Map(Arg.Any<IEnumerable<ControllableField>>())
                                .Returns(x => x[0]);

            return new CaseViewSectionsResolver(Db, _criteriaReader, securityContext, preferredCultureResolver, _caseViewFieldMapper, _subjectSecurity);
        }

        [Theory]
        [InlineData(KnownCaseScreenTopics.Image)]
        [InlineData(KnownCaseScreenTopics.CaseHeader)]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldReturnControllableFieldsInSummarySection(string topicName)
        {
            _criteriaReader.TryGetScreenCriteriaId(_caseId, _programId, out _)
                           .Returns(x =>
                           {
                               x[2] = _screenCriteriaId;
                               return true;
                           });

            var summaryTopicWithControllableFields = new TopicControl(_caseViewWindowControl, topicName).In(Db);

            var customisedField = new ElementControl(summaryTopicWithControllableFields, Fixture.String(), Fixture.String(), Fixture.String(), Fixture.Boolean()).In(Db);

            summaryTopicWithControllableFields.ElementControls.Add(customisedField);

            _caseViewWindowControl.TopicControls.Add(summaryTopicWithControllableFields);

            var subject = CreateSubject();

            var r = await subject.Resolve(_caseId, _programId);

            Assert.Equal("summary", r.Sections.Single().Name);
            Assert.Equal(customisedField.IsHidden, r.Sections.Single().Fields.Single().Hidden);
            Assert.Equal(customisedField.FullLabel, r.Sections.Single().Fields.Single().Label);
            Assert.Equal(customisedField.ElementName, r.Sections.Single().Fields.Single().FieldName);

            _caseViewFieldMapper.Received(1).Map(Arg.Is<IEnumerable<ControllableField>>(x => x.Any(y => y.FieldName == customisedField.ElementName)));
        }

        [Theory]
        [InlineData(KnownCaseScreenTopics.Image)]
        [InlineData(KnownCaseScreenTopics.CaseHeader)]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldNotHaveCaseHeaderSummarySectionIfHeaderNotModified(string topicName)
        {
            _criteriaReader.TryGetScreenCriteriaId(_caseId, _programId, out _)
                           .Returns(x =>
                           {
                               x[2] = _screenCriteriaId;
                               return true;
                           });

            _caseViewWindowControl.TopicControls.Add(new TopicControl(_caseViewWindowControl, topicName).In(Db));

            var subject = CreateSubject();

            var r = await subject.Resolve(_caseId, _programId);

            Assert.Empty(r.Sections);

            _caseViewFieldMapper.DidNotReceive().Map(Arg.Any<IEnumerable<ControllableField>>());
        }

        [Theory]
        [InlineData("NameTypeKey")]
        [InlineData("TextTypeKey")]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldReturnSectionsFromKnownFilteredTopic(string knownFilterName)
        {
            _criteriaReader.TryGetScreenCriteriaId(_caseId, _programId, out _)
                           .Returns(x =>
                           {
                               x[2] = _screenCriteriaId;
                               return true;
                           });

            var tab1 = new TabControl {WindowControlId = _caseViewWindowControl.Id}.In(Db);

            var topicSource1 = new TopicControl(_caseViewWindowControl, tab1, Fixture.String())
            {
                Title = Fixture.String(),
                TopicSuffix = Fixture.String()
            }.In(Db);

            var filterSource1 = new TopicControlFilter(knownFilterName, Fixture.String());
            topicSource1.Filters.Add(filterSource1);

            var tab2 = new TabControl {WindowControlId = _caseViewWindowControl.Id}.In(Db);

            var topicSource2 = new TopicControl(_caseViewWindowControl, tab2, Fixture.String())
            {
                Title = Fixture.String(),
                TopicSuffix = Fixture.String()
            }.In(Db);

            var filterSource2 = new TopicControlFilter(knownFilterName, Fixture.String());
            topicSource2.Filters.Add(filterSource2);

            var subject = CreateSubject();

            var r = await subject.Resolve(_caseId, _programId);

            Assert.Equal(topicSource1.Name, r.Sections.First().Name, StringComparer.OrdinalIgnoreCase);
            Assert.Equal(topicSource1.Title, r.Sections.First().Title);
            Assert.Equal(topicSource1.TopicSuffix, r.Sections.First().Suffix);

            Assert.Equal(filterSource1.FilterName, r.Sections.First().Filters.Keys.Single());
            Assert.Equal(filterSource1.FilterValue, r.Sections.First().Filters.Values.Single());

            Assert.Empty(r.Sections.First().Fields);

            Assert.Equal(topicSource2.Name, r.Sections.Last().Name, StringComparer.OrdinalIgnoreCase);
            Assert.Equal(topicSource2.Title, r.Sections.Last().Title);
            Assert.Equal(topicSource2.TopicSuffix, r.Sections.Last().Suffix);

            Assert.Equal(filterSource2.FilterName, r.Sections.Last().Filters.Keys.Single());
            Assert.Equal(filterSource2.FilterValue, r.Sections.Last().Filters.Values.Single());

            Assert.Empty(r.Sections.Last().Fields);
        }

        [Theory]
        [InlineData("TextTypeKey", "Case_TextTopic", "caseText")]
        [InlineData("NameTypeKey", "Case_NameTopic", "caseName")]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldReturnCombinedSectionsFromKnownFilteredTopicWithinTabs(string knownFilterName, string topicBaseName, string expectedSectionName)
        {
            _criteriaReader.TryGetScreenCriteriaId(_caseId, _programId, out _)
                           .Returns(x =>
                           {
                               x[2] = _screenCriteriaId;
                               return true;
                           });

            var tab = new TabControl {WindowControlId = _caseViewWindowControl.Id}.In(Db);

            var topicSource1 = new TopicControl(_caseViewWindowControl, tab, Fixture.String(topicBaseName + "_cloned_"))
            {
                Title = Fixture.String(),
                TopicSuffix = Fixture.String()
            }.In(Db);

            var filterSource1 = new TopicControlFilter(knownFilterName, Fixture.String());
            topicSource1.Filters.Add(filterSource1);

            var topicSource2 = new TopicControl(_caseViewWindowControl, tab, Fixture.String(topicBaseName + "_cloned_"))
            {
                Title = Fixture.String(),
                TopicSuffix = Fixture.String()
            }.In(Db);

            var filterSource2 = new TopicControlFilter(knownFilterName, Fixture.String());
            topicSource2.Filters.Add(filterSource2);

            var subject = CreateSubject();

            var r = await subject.Resolve(_caseId, _programId);

            Assert.Equal(tab.Title, r.Sections.Single().Title);

            Assert.Equal(expectedSectionName, r.Sections.Single().Name);
            Assert.Equal(topicSource1.TopicSuffix, r.Sections.Single().Suffix);

            Assert.Equal(knownFilterName, r.Sections.Single().Filters.Keys.Single());
            Assert.Equal(new[] {filterSource1.FilterValue, filterSource2.FilterValue}, r.Sections.Single().Filters.Values.Single().Split(','));

            Assert.Empty(r.Sections.Single().Fields);
        }

        [Theory]
        [InlineData("NameTypeKey")]
        [InlineData("TextTypeKey")]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldNotGroupDifferentTopicTypes(string knownFilterName)
        {
            _criteriaReader.TryGetScreenCriteriaId(_caseId, _programId, out _)
                           .Returns(x =>
                           {
                               x[2] = _screenCriteriaId;
                               return true;
                           });

            var tab = new TabControl {WindowControlId = _caseViewWindowControl.Id}.In(Db);

            var knownFilterTopic = new TopicControl(_caseViewWindowControl, tab, Fixture.String())
            {
                Title = "Filtered Topic Group Candidate",
                TopicSuffix = Fixture.String()
            }.In(Db);

            var filterSource1 = new TopicControlFilter(knownFilterName, Fixture.String());
            knownFilterTopic.Filters.Add(filterSource1);

            new TopicControl(_caseViewWindowControl, tab, Fixture.String())
            {
                Title = "Multiple Filters",
                TopicSuffix = Fixture.String(),
                Filters =
                {
                    new TopicControlFilter(Fixture.String(), Fixture.String()),
                    new TopicControlFilter(Fixture.String(), Fixture.String())
                }
            }.In(Db);

            new TopicControl(_caseViewWindowControl, tab, Fixture.String())
            {
                Title = "No Filters",
                TopicSuffix = Fixture.String()
            }.In(Db);

            var subject = CreateSubject();

            var r = await subject.Resolve(_caseId, _programId);

            Assert.Equal(knownFilterTopic.Title, r.Sections.First().Title);
            Assert.Equal(knownFilterTopic.Name, r.Sections.First().Name, StringComparer.OrdinalIgnoreCase);
            Assert.Equal(knownFilterTopic.TopicSuffix, r.Sections.First().Suffix);

            Assert.Equal(knownFilterName, r.Sections.First().Filters.Keys.Single());
            Assert.Equal(filterSource1.FilterValue, r.Sections.First().Filters.Values.Single());

            Assert.Empty(r.Sections.First().Fields);

            Assert.Equal(3, r.Sections.Count);
        }

        [Theory]
        [InlineData("TextTypeKey")]
        [InlineData("NameTypeKey")]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldNotGroupTopicsWithUnknownFilters(string knownFilterName)
        {
            _criteriaReader.TryGetScreenCriteriaId(_caseId, _programId, out _)
                           .Returns(x =>
                           {
                               x[2] = _screenCriteriaId;
                               return true;
                           });

            var tab = new TabControl {WindowControlId = _caseViewWindowControl.Id}.In(Db);

            var topicSource = new TopicControl(_caseViewWindowControl, tab, Fixture.String())
            {
                Title = Fixture.String(),
                TopicSuffix = Fixture.String()
            }.In(Db);

            var knownFilterSource = new TopicControlFilter(knownFilterName, Fixture.String());
            topicSource.Filters.Add(knownFilterSource);

            var unknownFilterTopic = new TopicControl(_caseViewWindowControl, tab, Fixture.String())
            {
                Title = Fixture.String(),
                TopicSuffix = Fixture.String()
            }.In(Db);

            var unknownFilterSource = new TopicControlFilter(Fixture.String(), Fixture.String());
            unknownFilterTopic.Filters.Add(unknownFilterSource);

            var subject = CreateSubject();

            var r = await subject.Resolve(_caseId, _programId);

            Assert.Equal(topicSource.Name, r.Sections.First().Name, StringComparer.OrdinalIgnoreCase);
            Assert.Equal(topicSource.Title, r.Sections.First().Title);
            Assert.Equal(topicSource.TopicSuffix, r.Sections.First().Suffix);

            Assert.Equal(unknownFilterTopic.Name, r.Sections.Last().Name, StringComparer.OrdinalIgnoreCase);
            Assert.Equal(unknownFilterTopic.Title, r.Sections.Last().Title);
            Assert.Equal(unknownFilterTopic.TopicSuffix, r.Sections.Last().Suffix);
        }

        [Theory]
        [InlineData("TextTypeKey", "CaseText")]
        [InlineData("NameTypeKey", "CaseName")]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldNotGroupTopicsWithUnsetFilter(string knownFilterName, string baseTopicName)
        {
            _criteriaReader.TryGetScreenCriteriaId(_caseId, _programId, out _)
                           .Returns(x =>
                           {
                               x[2] = _screenCriteriaId;
                               return true;
                           });

            var tab = new TabControl {WindowControlId = _caseViewWindowControl.Id}.In(Db);

            var topicSource1 = new TopicControl(_caseViewWindowControl, tab, Fixture.String(baseTopicName))
            {
                Title = Fixture.String(),
                TopicSuffix = Fixture.String(),
                Filters = {new TopicControlFilter(knownFilterName, Fixture.String())}
            }.In(Db);

            var topicSource2 = new TopicControl(_caseViewWindowControl, tab, Fixture.String(baseTopicName))
            {
                Title = "This topic has no filter value eventhough the filter name is known",
                TopicSuffix = Fixture.String(),
                Filters = {new TopicControlFilter(knownFilterName, null)}
            }.In(Db);

            var subject = CreateSubject();

            var r = await subject.Resolve(_caseId, _programId);

            Assert.Equal(topicSource1.Name, r.Sections.First().Name, StringComparer.OrdinalIgnoreCase);
            Assert.Equal(topicSource1.Title, r.Sections.First().Title);
            Assert.Equal(topicSource1.TopicSuffix, r.Sections.First().Suffix);

            Assert.Equal(topicSource2.Name, r.Sections.Last().Name, StringComparer.OrdinalIgnoreCase);
            Assert.Equal(topicSource2.Title, r.Sections.Last().Title);
            Assert.Equal(topicSource2.TopicSuffix, r.Sections.Last().Suffix);
        }

        [Theory]
        [InlineData("Images_Component", "images")]
        [InlineData("Attributes_Component", "attributes")]
        [InlineData("RelatedCases_Component", "relatedCases")]
        [InlineData("Actions_Component", "actions")]
        [InlineData("CaseBilling_Component", "caseBilling")]
        [InlineData("CriticalDates_Component", "criticalDates")]
        [InlineData("PriorArt_Component", "priorArt")]
        [InlineData("DesignatedCountries_Component", "designatedCountries")]
        [InlineData("Names_Component_cloned_1519958513412", "names")]
        [InlineData("Checklist_Component", "checklist")]
        [InlineData("CaseFirstUse_Component", "caseFirstUse")]
        [InlineData("OfficialNumbers_Component", "officialNumbers")]
        [InlineData("Case_TextTopic_cloned_1530230397754", "caseText")]
        [InlineData("ContactActivitySummary_Component", "contactActivitySummary")]
        [InlineData("WIP_Component", "wIP")]
        [InlineData("DesignElement_Component", "designElement")]
        [InlineData("RecentContacts_Component", "recentContacts")]
        [InlineData("PTA_Component", "pTA")]
        [InlineData("BillingInstructions_Component", "billingInstructions")]
        [InlineData("Events_Component", "events")]
        [InlineData("CaseOtherDetails_Component", "caseOtherDetails")]
        [InlineData("Case_TextTopic", "caseText")]
        [InlineData("CRMCaseStatusHistory_Component", "cRMCaseStatusHistory")]
        [InlineData("MarketingActivities_HeaderTopic", "marketingActivities_Header")]
        [InlineData("Names_Component", "names")]
        [InlineData("FileLocations_Component", "fileLocations")]
        [InlineData("CaseRenewals_Component", "caseRenewals")]
        [InlineData("Classes_Component", "classes")]
        [InlineData("CaseStandingInstructions_Component", "caseStandingInstructions")]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldTransformTopicNames(string topicRawName, string expectedSectionName)
        {
            _criteriaReader.TryGetScreenCriteriaId(_caseId, _programId, out _)
                           .Returns(x =>
                           {
                               x[2] = _screenCriteriaId;
                               return true;
                           });

            new TopicControl(_caseViewWindowControl, new TabControl
            {
                WindowControlId = _caseViewWindowControl.Id
            }.In(Db), topicRawName).In(Db);

            var subject = CreateSubject();

            var r = await subject.Resolve(_caseId, _programId);

            Assert.Equal(expectedSectionName, r.Sections.Single().Name);
        }

        [Fact]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldNotResolveProgramIdIfPassedIn()
        {
            var programId = Fixture.String();

            var subject = CreateSubject(new User(Fixture.String(), false));

            var _ = await subject.Resolve(_caseId, programId);

            _criteriaReader.Received(1).TryGetScreenCriteriaId(_caseId, programId, out var _);
        }

        [Fact]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldResolveProgramIdCaseScreenDefaultForInternalUser()
        {
            var programId = Fixture.String();

            var programSiteControl = new SiteControl(SiteControls.CaseScreenDefaultProgram).In(Db);
            programSiteControl.StringValue = programId;

            var subject = CreateSubject(new User(Fixture.String(), false));

            var _ = await subject.Resolve(_caseId);

            _criteriaReader.Received(1).TryGetScreenCriteriaId(_caseId, programId, out var _);
        }

        [Fact]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldResolveProgramIdClientAccessForExternalUser()
        {
            var programId = Fixture.String();

            var programSiteControl = new SiteControl(SiteControls.CaseProgramForClientAccess).In(Db);
            programSiteControl.StringValue = programId;

            var subject = CreateSubject(new User(Fixture.String(), true));

            var _ = await subject.Resolve(_caseId);

            _criteriaReader.Received(1).TryGetScreenCriteriaId(_caseId, programId, out var _);
        }

        [Fact]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldResolveProgramIdFromProfileAttribute()
        {
            var programId = Fixture.String();
            var profile = new ProfileBuilder().Build().In(Db);
            profile.ProfileAttributes.Add(new ProfileAttribute(profile, ProfileAttributeType.DefaultCaseProgram, programId).In(Db));

            var subject = CreateSubject(new User(Fixture.String(), Fixture.Boolean(), profile));

            var _ = await subject.Resolve(_caseId);

            _criteriaReader.Received(1).TryGetScreenCriteriaId(_caseId, programId, out var _);
        }

        [Fact]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldReturnImmediatelyIfScreenCriteriaNotFound()
        {
            var programId = Fixture.String();

            _criteriaReader.TryGetScreenCriteriaId(_caseId, programId, out _)
                           .Returns(false);

            var subject = CreateSubject();

            var r = await subject.Resolve(_caseId, programId);

            Assert.Null(r.ScreenCriterion);
            Assert.Equal(programId, r.ProgramId);
        }

        [Fact]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldReturnSectionsBasedOnExistingTabOrders()
        {
            _criteriaReader.TryGetScreenCriteriaId(_caseId, _programId, out _)
                           .Returns(x =>
                           {
                               x[2] = _screenCriteriaId;
                               return true;
                           });

            (TabControl tab, TopicControl topic) CreateTabTopic(short displaySequence)
            {
                var tab = new TabControl {WindowControlId = _caseViewWindowControl.Id, DisplaySequence = displaySequence}.In(Db);

                var topic = new TopicControl(_caseViewWindowControl, tab, Fixture.String())
                {
                    Title = Fixture.String()
                }.In(Db);

                return (tab, topic);
            }

            var expectedSequence = new[]
                {
                    CreateTabTopic(5),
                    CreateTabTopic(4),
                    CreateTabTopic(3),
                    CreateTabTopic(2),
                    CreateTabTopic(1)
                }.OrderBy(_ => _.tab.DisplaySequence)
                 .Select(_ => _.topic.Title);

            var subject = CreateSubject();

            var r = await subject.Resolve(_caseId, _programId);

            Assert.Equal(expectedSequence, r.Sections.Select(_ => _.Title));
        }

        [Fact]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldReturnSectionsFromGeneralTopic()
        {
            _criteriaReader.TryGetScreenCriteriaId(_caseId, _programId, out _)
                           .Returns(x =>
                           {
                               x[2] = _screenCriteriaId;
                               return true;
                           });

            var topicSource = new TopicControl(_caseViewWindowControl, Fixture.String())
            {
                Title = Fixture.String(),
                TopicSuffix = Fixture.String()
            }.In(Db);

            _caseViewWindowControl.TopicControls.Add(topicSource);

            var subject = CreateSubject();

            var r = await subject.Resolve(_caseId, _programId);

            Assert.Equal(topicSource.Name, r.Sections.Single().Name, StringComparer.OrdinalIgnoreCase);
            Assert.Equal(topicSource.Title, r.Sections.Single().Title);
            Assert.Equal(topicSource.TopicSuffix, r.Sections.Single().Suffix);
            Assert.Empty(r.Sections.Single().Fields);
            Assert.Empty(r.Sections.Single().Filters);
        }

        [Fact]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldReturnSectionsFromGeneralTopicWithinTabs()
        {
            _criteriaReader.TryGetScreenCriteriaId(_caseId, _programId, out _)
                           .Returns(x =>
                           {
                               x[2] = _screenCriteriaId;
                               return true;
                           });

            var tab = new TabControl {WindowControlId = _caseViewWindowControl.Id}.In(Db);

            var topicSource = new TopicControl(_caseViewWindowControl, tab, Fixture.String())
            {
                Title = Fixture.String(),
                TopicSuffix = Fixture.String()
            }.In(Db);

            var subject = CreateSubject();

            var r = await subject.Resolve(_caseId, _programId);

            Assert.Equal(topicSource.Name, r.Sections.Single().Name, StringComparer.OrdinalIgnoreCase);
            Assert.Equal(topicSource.Title, r.Sections.Single().Title);
            Assert.Equal(topicSource.TopicSuffix, r.Sections.Single().Suffix);
            Assert.Empty(r.Sections.Single().Fields);
            Assert.Empty(r.Sections.Single().Filters);
        }

        [Fact]
        [Trait("Category", CaseViewScreenControl)]
        public async Task ShouldReturnSubsectionsWhereConfigured()
        {
            _criteriaReader.TryGetScreenCriteriaId(_caseId, _programId, out _)
                           .Returns(x =>
                           {
                               x[2] = _screenCriteriaId;
                               return true;
                           });

            var eventsTopic = new TopicControl(_caseViewWindowControl, KnownCaseScreenTopics.Events)
            {
                Title = Fixture.String(),
                TopicSuffix = Fixture.String()
            }.In(Db);

            _caseViewWindowControl.TopicControls.Add(eventsTopic);

            if (_caseViewWindowControl.CriteriaId != null)
            {
                var caseEventsWindowControl = new WindowControl((int)_caseViewWindowControl.CriteriaId, "CaseEvents").In(Db);

                var dueEventsSubTopic = new TopicControl(caseEventsWindowControl, KnownCaseScreenTopics.EventsDueHeader) {Title = Fixture.String()}.In(Db);
                var occurredEventsSubTopic = new TopicControl(caseEventsWindowControl, KnownCaseScreenTopics.EventsOccurredHeader) {Title = Fixture.String()}.In(Db);

                var subject = CreateSubject();

                var r = await subject.Resolve(_caseId, _programId);

                Assert.Equal(eventsTopic.Title, r.Sections.Single().Title);
                Assert.Equal(dueEventsSubTopic.Title, r.Sections.Single().SubTopics.First().Title);
                Assert.Equal(occurredEventsSubTopic.Title, r.Sections.Single().SubTopics.Last().Title);
            }
        }
    }
}