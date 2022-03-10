using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Cases.Screens;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Screens
{
    public class CaseViewSectionsTaskSecurityFacts
    {
        readonly CaseViewSectionsTaskSecurity _f;
        readonly ITaskSecurityProvider _taskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

        public CaseViewSectionsTaskSecurityFacts()
        {
            _f = new CaseViewSectionsTaskSecurity(_taskSecurityProvider);
        }

        [Fact]
        public void ReturnsScreenControlIfAccessIsSet()
        {
            _taskSecurityProvider.HasAccessTo(Arg.Any<ApplicationTask>()).Returns(true);
            var sc = new List<CaseViewSection>()
            {
                new CaseViewSection() {TopicName = Fixture.String()},
                new CaseViewSection() {TopicName = KnownCaseScreenTopics.Dms}
            };

            var r = _f.Filter(sc);

            Assert.Equal(2, r.Count);
        }

        [Fact]
        public void OnlyFiltersOutConfiguredDMSSection()
        {
            _taskSecurityProvider.HasAccessTo(Arg.Any<ApplicationTask>()).Returns(false);
            var sc = new List<CaseViewSection>()
            {
                new CaseViewSection() {TopicName = Fixture.String()},
                new CaseViewSection() {TopicName = KnownCaseScreenTopics.Dms}
            };

            var r = _f.Filter(sc);

            Assert.Equal(1, r.Count);
            Assert.Equal(sc[0].TopicName, r.First().TopicName);
        }
    }
}