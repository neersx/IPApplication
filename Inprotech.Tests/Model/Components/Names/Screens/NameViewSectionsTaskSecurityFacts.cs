using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Names.Screens;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Names.Screens
{
    public class NameViewSectionsTaskSecurityFacts
    {
        public NameViewSectionsTaskSecurityFacts()
        {
            _f = new NameViewSectionsTaskSecurity(_taskSecurityProvider);
        }

        readonly NameViewSectionsTaskSecurity _f;
        readonly ITaskSecurityProvider _taskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

        [Fact]
        public void OnlyFiltersOutConfiguredDMSSection()
        {
            _taskSecurityProvider.HasAccessTo(Arg.Any<ApplicationTask>()).Returns(false);
            var sc = new List<NameViewSection>
            {
                new NameViewSection {TopicName = Fixture.String()},
                new NameViewSection {TopicName = KnownCaseScreenTopics.Dms}
            };

            var r = _f.Filter(sc);

            Assert.Equal(1, r.Count);
            Assert.Equal(sc[0].TopicName, r.First().TopicName);
        }

        [Fact]
        public void ReturnsScreenControlIfAccessIsSet()
        {
            _taskSecurityProvider.HasAccessTo(Arg.Any<ApplicationTask>()).Returns(true);
            var sc = new List<NameViewSection>
            {
                new NameViewSection {TopicName = Fixture.String()},
                new NameViewSection {TopicName = KnownCaseScreenTopics.Dms}
            };

            var r = _f.Filter(sc);

            Assert.Equal(2, r.Count);
        }
    }
}