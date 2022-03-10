using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Components.Cases.Screens;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class ScreenControlControllerFacts
    {
        readonly int _caseId = Fixture.Integer();
        readonly ICaseViewSectionsResolver _caseViewSectionsResolver = Substitute.For<ICaseViewSectionsResolver>();
        readonly ICaseViewSectionsTaskSecurity _caseViewSectionsTaskSecurity = Substitute.For<ICaseViewSectionsTaskSecurity>();

        public ScreenControlControllerFacts()
        {
            _caseViewSectionsTaskSecurity.Filter(Arg.Any<List<CaseViewSection>>()).ReturnsForAnyArgs(args => args[0]);
        }

        [Fact]
        public async Task ShouldReturnConfiguredSections()
        {
            var r = new CaseViewSections
            {
                ScreenCriterion = Fixture.Integer(),
                Sections = new List<CaseViewSection>() { new CaseViewSection() { TopicName = Fixture.String() } }
            };

            _caseViewSectionsResolver.Resolve(_caseId)
                                     .Returns(r);

            var subject = new ScreenControlController(_caseViewSectionsResolver, _caseViewSectionsTaskSecurity);

            var results = await subject.GetScreenControl(_caseId);

            Assert.Equal(r.Sections, results.Topics);
        }

        [Fact]
        public async Task ShouldReturnNullIfScreenCriterionNotFound()
        {
            _caseViewSectionsResolver.Resolve(_caseId)
                                     .Returns(new CaseViewSections());

            var subject = new ScreenControlController(_caseViewSectionsResolver, _caseViewSectionsTaskSecurity);

            var results = await subject.GetScreenControl(_caseId);

            Assert.Null(results);
        }

        [Fact]
        public async Task ShouldPassinProgramId()
        {
            _caseViewSectionsResolver.Resolve(_caseId, Arg.Any<string>())
                                     .Returns(new CaseViewSections());

            var subject = new ScreenControlController(_caseViewSectionsResolver, _caseViewSectionsTaskSecurity);

            await subject.GetScreenControl(_caseId, "CASEOPT");

            await _caseViewSectionsResolver.Received(1).Resolve(_caseId, "CASEOPT");

        }

        [Fact]
        public async Task ShouldReturnConfiguredSectionsAfterCheckingTaskSecurity()
        {
            var authorizedTopic = new CaseViewSection()
            {
                TopicName = Fixture.String()

            };
            var r = new CaseViewSections
            {
                ScreenCriterion = Fixture.Integer(),
                Sections = new List<CaseViewSection>()
                {
                    new CaseViewSection()
                    {
                        TopicName = Fixture.String()

                    },
                    authorizedTopic
                }
            };

            _caseViewSectionsResolver.Resolve(_caseId)
                                     .Returns(r);
            _caseViewSectionsTaskSecurity.Filter(r.Sections).Returns(new[] { authorizedTopic });

            var subject = new ScreenControlController(_caseViewSectionsResolver, _caseViewSectionsTaskSecurity);

            var results = await subject.GetScreenControl(_caseId);
            var sections = (ICollection<CaseViewSection>)results.Topics;

            Assert.Equal(1, sections.Count);
            Assert.Equal(authorizedTopic.TopicName, sections.First().TopicName);
        }
    }
}