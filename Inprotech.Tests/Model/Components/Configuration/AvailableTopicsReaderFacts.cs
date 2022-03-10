using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Configuration.Screens;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Configuration
{
    public class AvailableTopicsReaderFacts : FactBase
    {
        public AvailableTopicsReaderFacts()
        {
            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            _subject = new AvailableTopicsReader(Db, preferredCultureResolver);
        }

        readonly IAvailableTopicsReader _subject;

        [Fact]
        public void IndicatesWebScreens()
        {
            new Screen
            {
                ScreenName = "frmOne",
                ScreenTitle = "One",
                ScreenType = "a"
            }.In(Db);

            new TopicUsage
            {
                TopicName = "frmOne",
                TopicTitle = "One",
                TopicType = "b"
            }.In(Db);

            var r = _subject.Retrieve().ToArray();

            Assert.Single(r);
            Assert.Equal("frmOne", r[0].Key);
            Assert.Equal("One", r[0].DefaultTitle);
            Assert.True(r[0].IsWebEnabled);
        }

        [Fact]
        public void ReturnsAvailableTopics()
        {
            new Screen
            {
                ScreenName = "frmOne",
                ScreenTitle = "One",
                ScreenType = "a"
            }.In(Db);

            new Screen
            {
                ScreenName = "frmTwo",
                ScreenTitle = "Two",
                ScreenType = "b"
            }.In(Db);

            var r = _subject.Retrieve().ToArray();

            Assert.Equal(2, r.Count());
            Assert.Equal("frmOne", r[0].Key);
            Assert.Equal("One", r[0].DefaultTitle);
            Assert.False(r[0].IsWebEnabled);
            Assert.Equal("frmTwo", r[1].Key);
            Assert.Equal("Two", r[1].DefaultTitle);
            Assert.False(r[1].IsWebEnabled);
        }

        [Fact]
        public void ReturnsWebScreensDetailsOverClassicScreens()
        {
            new Screen
            {
                ScreenName = "frmOne",
                ScreenTitle = "One",
                ScreenType = "a"
            }.In(Db);

            new TopicUsage
            {
                TopicName = "frmOne",
                TopicTitle = "OneOneOne",
                TopicType = "b2"
            }.In(Db);

            var r = _subject.Retrieve().ToArray();

            Assert.Single(r);
            Assert.Equal("frmOne", r[0].Key);
            Assert.Equal("OneOneOne", r[0].DefaultTitle);
            Assert.Equal("b2", r[0].Type);
            Assert.True(r[0].IsWebEnabled);
        }
    }
}