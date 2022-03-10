using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Configuration;
using NSubstitute;
using Xunit;
using AvailableTopicsModel = InprotechKaizen.Model.Components.Configuration.AvailableTopic;
using AvailableTopicsMatched = Inprotech.Web.Picklists.AvailableTopic;

namespace Inprotech.Tests.Web.Picklists
{
    public class AvailableTopicPicklistControllerFacts
    {
        readonly IAvailableTopicsReader _reader = Substitute.For<IAvailableTopicsReader>();
        readonly IResolvedCultureTranslations _translations = Substitute.For<IResolvedCultureTranslations>();

        [Fact]
        public void DoesNotExcludeIfNotEntrySteps()
        {
            var screenKeys = new[] {"frmEDECaseResolutionA", "frmEDECaseResolutionB", "frmCaseDetail", "frmLetters", "otherScreen1", "otherScreen2"};

            _reader.Retrieve()
                   .Returns(screenKeys.Select(_ => new AvailableTopicsModel {Key = _})
                                      .AsQueryable());

            var subject = new AvailableTopicPicklistController(_reader, _translations);
            var r = subject.Topics(null, null, "otherTypeOfstep").Data.Cast<AvailableTopicsMatched>().ToArray();

            Assert.Equal(6, r.Length);
        }

        [Fact]
        public void ExcludesCertainScreensIfEntrySteps()
        {
            var screenKeys = new[] {"frmEDECaseResolutionA", "frmEDECaseResolutionB", "frmCaseDetail", "frmLetters", "otherScreen1", "otherScreen2"};

            _reader.Retrieve()
                   .Returns(screenKeys.Select(_ => new AvailableTopicsModel {Key = _})
                                      .AsQueryable());

            var subject = new AvailableTopicPicklistController(_reader, _translations);
            var r = subject.Topics().Data.Cast<AvailableTopicsMatched>().ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal("otherScreen1", r[0].Key);
            Assert.Equal("otherScreen2", r[1].Key);
        }

        [Fact]
        public void ReturnsCategoryDescription()
        {
            _reader.Retrieve()
                   .Returns(new[]
                            {
                                new AvailableTopicsModel
                                {
                                    Key = "frmOne",
                                    DefaultClassicTitle = "One",
                                    Type = "T "
                                },
                                new AvailableTopicsModel
                                {
                                    Key = "frmTwo",
                                    DefaultClassicTitle = "Two",
                                    Type = "M "
                                }
                            }.AsQueryable()
                           );

            _translations["workflows.entrycontrol.steps.textType"].Returns("Tahiti");
            _translations["workflows.entrycontrol.steps.mandatoryRelationship"].Returns("manuka honey");

            var subject = new AvailableTopicPicklistController(_reader, _translations);

            var r = subject.Topics(search: "o").Data.Cast<AvailableTopicsMatched>().ToArray();

            Assert.Equal("frmOne", r[0].Key);
            Assert.Equal("Tahiti", r[0].TypeDescription);

            Assert.Equal("frmTwo", r[1].Key);
            Assert.Equal("manuka honey", r[1].TypeDescription);
        }

        [Fact]
        public void ReturnsDataInDefaultOrder()
        {
            _reader.Retrieve()
                   .Returns(new[]
                            {
                                new AvailableTopicsModel
                                {
                                    Key = "frmOne",
                                    DefaultClassicTitle = "One",
                                    IsWebEnabled = false
                                },
                                new AvailableTopicsModel
                                {
                                    Key = "frmOne1",
                                    DefaultClassicTitle = "One1",
                                    IsWebEnabled = false
                                },
                                new AvailableTopicsModel
                                {
                                    Key = "frmTwo",
                                    DefaultClassicTitle = "Two",
                                    IsWebEnabled = true
                                },
                                new AvailableTopicsModel
                                {
                                    Key = "frmTwo1",
                                    DefaultClassicTitle = "Two1",
                                    IsWebEnabled = true
                                }
                            }.AsQueryable()
                           );

            var subject = new AvailableTopicPicklistController(_reader, _translations);

            var r = subject.Topics().Data.Cast<AvailableTopicsMatched>().ToArray();

            Assert.Equal(4, r.Length);
            Assert.Equal("frmTwo", r[0].Key);
            Assert.Equal("frmTwo1", r[1].Key);
            Assert.Equal("frmOne", r[2].Key);
            Assert.Equal("frmOne1", r[3].Key);
        }

        [Fact]
        public void ReturnsDataInOrderProvided()
        {
            _reader.Retrieve()
                   .Returns(new[]
                            {
                                new AvailableTopicsModel
                                {
                                    Key = "frmOne",
                                    DefaultClassicTitle = "One",
                                    IsWebEnabled = false
                                },
                                new AvailableTopicsModel
                                {
                                    Key = "frmOne1",
                                    DefaultClassicTitle = "One1",
                                    IsWebEnabled = false
                                },
                                new AvailableTopicsModel
                                {
                                    Key = "frmTwo",
                                    DefaultClassicTitle = "Two",
                                    IsWebEnabled = true
                                },
                                new AvailableTopicsModel
                                {
                                    Key = "frmTwo1",
                                    DefaultClassicTitle = "Two1",
                                    IsWebEnabled = true
                                }
                            }.AsQueryable()
                           );

            var subject = new AvailableTopicPicklistController(_reader, _translations);

            var r = subject.Topics(new CommonQueryParameters {SortBy = "DefaultTitle", SortDir = "asc"}).Data.Cast<AvailableTopicsMatched>().ToArray();

            Assert.Equal(4, r.Length);
            Assert.Equal("frmOne", r[0].Key);
            Assert.Equal("frmOne1", r[1].Key);
            Assert.Equal("frmTwo", r[2].Key);
            Assert.Equal("frmTwo1", r[3].Key);
        }

        [Fact]
        public void ReturnsExactMatch()
        {
            _reader.Retrieve()
                   .Returns(new[]
                            {
                                new AvailableTopicsModel
                                {
                                    Key = "frmOne",
                                    DefaultClassicTitle = "One",
                                    Type = "T"
                                },
                                new AvailableTopicsModel
                                {
                                    Key = "frmTwo",
                                    DefaultClassicTitle = "Two",
                                    Type = "X"
                                }
                            }.AsQueryable()
                           );

            var subject = new AvailableTopicPicklistController(_reader, _translations);
            var r = subject.Topics(search: "Two").Data.Cast<AvailableTopicsMatched>().ToArray();

            Assert.Single(r);
            Assert.Equal("frmTwo", r[0].Key);
            Assert.Equal("Two", r[0].DefaultTitle);
        }

        [Fact]
        public void ReturnsPartialMatchesOnTitle()
        {
            _reader.Retrieve()
                   .Returns(new[]
                            {
                                new AvailableTopicsModel
                                {
                                    Key = "frmOne",
                                    DefaultClassicTitle = "One",
                                    Type = "G"
                                },
                                new AvailableTopicsModel
                                {
                                    Key = "frmTwo",
                                    DefaultClassicTitle = "Two",
                                    Type = "M"
                                }
                            }.AsQueryable()
                           );

            var subject = new AvailableTopicPicklistController(_reader, _translations);

            var r = subject.Topics(search: "o").Data.Cast<AvailableTopicsMatched>().ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal("frmOne", r[0].Key);
            Assert.Equal("One", r[0].DefaultTitle);
            Assert.False(r[0].IsWebEnabled);
            Assert.Equal("frmTwo", r[1].Key);
            Assert.Equal("Two", r[1].DefaultTitle);
            Assert.False(r[1].IsWebEnabled);
        }
    }
}