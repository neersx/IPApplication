using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.Screens;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Names.Screens
{
    public class NameViewSectionResolverFacts : FactBase
    {
        public NameViewSectionResolverFacts()
        {
            _nameViewWindowControl = new WindowControl
            {
                NameCriteriaId = _nameCriteriaId,
                Name = "NameDetails"
            }.In(Db);
            _criteriaReader.TryGetNameScreenCriteriaId(_nameId, _programId, out _)
                           .Returns(x =>
                           {
                               x[2] = _nameViewWindowControl.NameCriteriaId;
                               return true;
                           });
            _subjectSecurity.HasAccessToSubject(ApplicationSubject.SupplierDetails).Returns(true);
            _subjectSecurity.HasAccessToSubject(ApplicationSubject.TrustAccounting).Returns(true);
        }

        readonly ICriteriaReader _criteriaReader = Substitute.For<ICriteriaReader>();
        readonly ISubjectSecurityProvider _subjectSecurity = Substitute.For<ISubjectSecurityProvider>();
        readonly INameViewSectionsTaskSecurity _nameViewSectionsTaskSecurity = Substitute.For<INameViewSectionsTaskSecurity>();
        readonly IDefaultNameTypeClassification _defaultNameTypeClassification = Substitute.For<IDefaultNameTypeClassification>();
        readonly int _nameId = Fixture.Integer();
        readonly int _nameCriteriaId = Fixture.Integer();
        readonly string _culture = Fixture.String();
        readonly string _programId = Fixture.String();
        readonly WindowControl _nameViewWindowControl;

        INameViewSectionsResolver CreateSubject(User user = null)
        {
            var theUser = user ?? new User(Fixture.String(), false).In(Db);
            var securityContext = Substitute.For<ISecurityContext>();
            securityContext.User.Returns(theUser);
            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            preferredCultureResolver.Resolve().Returns(_culture);

            return new NameViewSectionsResolver(Db, _criteriaReader, preferredCultureResolver, _subjectSecurity, _nameViewSectionsTaskSecurity, _defaultNameTypeClassification);
        }

        [Theory]
        [InlineData(KnownNameScreenTopics.SupplierDetails)]
        [InlineData(KnownNameScreenTopics.TrustAccounting)]
        public async Task ShouldReturnSubsectionsWhereConfiguredBasedOnSubjectSecurity(string topic)
        {
            var screenTopic = new TopicControl(_nameViewWindowControl, topic)
            {
                Title = Fixture.String(),
                TopicSuffix = Fixture.String()
            }.In(Db);
            _nameViewWindowControl.TopicControls.Add(screenTopic);
            var validNameTypeClassifications = new List<ValidNameTypeClassification> {new ValidNameTypeClassification {IsSelected = true, IsCrmOnly = false, NameTypeKey = KnownNameTypes.Debtor}};
            _defaultNameTypeClassification.FetchNameTypeClassification(Arg.Any<int?>(), Arg.Any<int?>()).Returns(validNameTypeClassifications);
            _nameViewSectionsTaskSecurity.Filter(Arg.Any<ICollection<NameViewSection>>())
                                         .Returns(x => x[0]);

            var subject = CreateSubject();
            var r = await subject.Resolve(_nameId, _programId);

            Assert.Equal(screenTopic.Title, r.Sections.Single().Title);
        }

        [Theory]
        [InlineData(KnownNameScreenTopics.Dms)]
        public async Task ShouldReturnSubsectionsWhereConfiguredBasedOnTaskSecurity(string topic)
        {
            var screenTopic = new TopicControl(_nameViewWindowControl, topic)
            {
                Title = Fixture.String(),
                TopicSuffix = Fixture.String()
            }.In(Db);
            _nameViewWindowControl.TopicControls.Add(screenTopic);
            var validNameTypeClassifications = new List<ValidNameTypeClassification> {new ValidNameTypeClassification {IsSelected = true, IsCrmOnly = false, NameTypeKey = KnownNameTypes.Debtor}};
            _defaultNameTypeClassification.FetchNameTypeClassification(Arg.Any<int?>(), Arg.Any<int?>()).Returns(validNameTypeClassifications);
            _nameViewSectionsTaskSecurity.Filter(Arg.Any<ICollection<NameViewSection>>())
                                         .Returns(x => x[0]);

            var subject = CreateSubject();
            var r = await subject.Resolve(_nameId, _programId);

            Assert.Equal(screenTopic.Title, r.Sections.Single().Title);
        }

        [Theory]
        [InlineData(KnownNameScreenTopics.SupplierDetails, ApplicationSubject.SupplierDetails, true)]
        [InlineData(KnownNameScreenTopics.SupplierDetails, ApplicationSubject.SupplierDetails, false)]
        [InlineData(KnownNameScreenTopics.TrustAccounting, ApplicationSubject.TrustAccounting, true)]
        [InlineData(KnownNameScreenTopics.TrustAccounting, ApplicationSubject.TrustAccounting, false)]
        public async Task ShouldNotReturnSubsectionsWhenHasNoAccessToSubjectSecurity(string topic, ApplicationSubject subjectSecurity, bool allow)
        {
            var supplierTopic = new TopicControl(_nameViewWindowControl, topic)
            {
                Title = Fixture.String(),
                TopicSuffix = Fixture.String()
            }.In(Db);
            _subjectSecurity.HasAccessToSubject(subjectSecurity).Returns(allow);
            _nameViewSectionsTaskSecurity.Filter(Arg.Any<ICollection<NameViewSection>>())
                                         .Returns(x => x[0]);

            var subject = CreateSubject();

            _nameViewWindowControl.TopicControls.Add(supplierTopic);
            var r = await subject.Resolve(_nameId, _programId);

            if (allow)
            {
                Assert.True(r.Sections.Count > 0);
            }
            else
            {
                Assert.True(r.Sections.Count == 0);
            }
        }

        [Theory]
        [InlineData(KnownNameScreenTopics.Dms)]
        public async Task ShouldNotReturnSubsectionsWhenHasNoAccessToTaskSecurity(string topic)
        {
            var topicNoAccess = new TopicControl(_nameViewWindowControl, topic)
            {
                Title = Fixture.String(),
                TopicSuffix = Fixture.String()
            }.In(Db);
            _nameViewSectionsTaskSecurity.Filter(Arg.Any<ICollection<NameViewSection>>())
                                         .Returns(x =>
                                         {
                                             var all = (ICollection<NameViewSection>) x[0];
                                             var noAccess = all.Single(_ => _.TopicName == topicNoAccess.Name);
                                             return all.Except(new []{ noAccess }).ToList();
                                         });

            var subject = CreateSubject();

            _nameViewWindowControl.TopicControls.Add(topicNoAccess);
            var r = await subject.Resolve(_nameId, _programId);
    
            Assert.Empty(r.Sections);
        }

        [Fact]
        public async Task ShouldResolveProgramIdCorrectlyForCrmName()
        {
            var crmNameTypeClassification = new List<ValidNameTypeClassification> {new ValidNameTypeClassification {IsSelected = true, IsCrmOnly = true, NameTypeKey = KnownNameTypes.Contact}};
            _defaultNameTypeClassification.FetchNameTypeClassification(Arg.Any<int?>(), Arg.Any<int?>()).Returns(crmNameTypeClassification);
            _nameViewSectionsTaskSecurity.Filter(Arg.Any<ICollection<NameViewSection>>())
                                         .Returns(x => x[0]);

            var subject = CreateSubject();
            var _ = await subject.Resolve(_nameId);

            _criteriaReader.Received(1).TryGetNameScreenCriteriaId(_nameId, KnownNamePrograms.NameCrm, out var _);
        }

        [Fact]
        public async Task ShouldReturnImmediatelyIfScreenCriteriaNotFound()
        {
            var programId = Fixture.String();
            _criteriaReader.TryGetScreenCriteriaId(_nameId, programId, out _)
                           .Returns(false);
            var validNameTypeClassifications = new List<ValidNameTypeClassification> {new ValidNameTypeClassification {IsSelected = true, IsCrmOnly = false, NameTypeKey = KnownNameTypes.Debtor}};
            _defaultNameTypeClassification.FetchNameTypeClassification(Arg.Any<int?>(), Arg.Any<int?>()).Returns(validNameTypeClassifications);
            _nameViewSectionsTaskSecurity.Filter(Arg.Any<ICollection<NameViewSection>>())
                                         .Returns(x => x[0]);

            var subject = CreateSubject();
            var r = await subject.Resolve(_nameId, programId);

            Assert.Null(r.ScreenNameCriteria);
            Assert.Equal(programId, r.ProgramId);
        }

        [Fact]
        public async Task ShouldReturnSectionsBasedOnExistingTabOrders()
        {
            _criteriaReader.TryGetScreenCriteriaId(_nameId, _programId, out _)
                           .Returns(x =>
                           {
                               x[2] = _nameCriteriaId;
                               return true;
                           });

            (TabControl tab, TopicControl topic) CreateTabTopic(short displaySequence)
            {
                var tab = new TabControl {WindowControlId = _nameViewWindowControl.Id, DisplaySequence = displaySequence}.In(Db);

                var topic = new TopicControl(_nameViewWindowControl, tab, Fixture.String())
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
            var validNameTypeClassifications = new List<ValidNameTypeClassification> {new ValidNameTypeClassification {IsSelected = true, IsCrmOnly = false, NameTypeKey = KnownNameTypes.Debtor}};
            _defaultNameTypeClassification.FetchNameTypeClassification(Arg.Any<int?>(), Arg.Any<int?>()).Returns(validNameTypeClassifications);
            _nameViewSectionsTaskSecurity.Filter(Arg.Any<ICollection<NameViewSection>>())
                                         .Returns(x => x[0]);

            var subject = CreateSubject();
            var r = await subject.Resolve(_nameId, _programId);

            Assert.Equal(expectedSequence, r.Sections.Select(_ => _.Title));
        }

        [Fact]
        public async Task ShouldReturnSectionsFromTopicWithinTabs()
        {
            _criteriaReader.TryGetScreenCriteriaId(_nameId, _programId, out _)
                           .Returns(x =>
                           {
                               x[2] = _nameCriteriaId;
                               return true;
                           });
            var tab = new TabControl {WindowControlId = _nameViewWindowControl.Id}.In(Db);
            var topicSource = new TopicControl(_nameViewWindowControl, tab, Fixture.String())
            {
                Title = Fixture.String(),
                TopicSuffix = Fixture.String()
            }.In(Db);
            var validNameTypeClassifications = new List<ValidNameTypeClassification> {new ValidNameTypeClassification {IsSelected = true, IsCrmOnly = false, NameTypeKey = KnownNameTypes.Debtor}};
            _defaultNameTypeClassification.FetchNameTypeClassification(Arg.Any<int?>(), Arg.Any<int?>()).Returns(validNameTypeClassifications);
            _nameViewSectionsTaskSecurity.Filter(Arg.Any<ICollection<NameViewSection>>())
                                         .Returns(x => x[0]);

            var subject = CreateSubject();
            var r = await subject.Resolve(_nameId, _programId);

            Assert.Equal(topicSource.Name, r.Sections.Single().Name, StringComparer.OrdinalIgnoreCase);
            Assert.Equal(topicSource.Title, r.Sections.Single().Title);
            Assert.Equal(topicSource.TopicSuffix, r.Sections.Single().Suffix);
            Assert.Empty(r.Sections.Single().Fields);
            Assert.Empty(r.Sections.Single().Filters);
        }
    }
}