using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;
using Event = InprotechKaizen.Model.Cases.Events.Event;

namespace Inprotech.Tests.Web.Picklists
{
    public class NumberTypePicklistControllerFacts : FactBase
    {
        public NumberTypePicklistControllerFacts()
        {
            _controller = new NumberTypesPicklistController(Db, Substitute.For<IPreferredCultureResolver>());
        }

        readonly NumberTypesPicklistController _controller;

        [Fact]
        public void ShouldOrderByExactMatchAndFollowedByDescriptionCode()
        {
            new NumberType("a3", "b", null).In(Db);
            new NumberType("a2", "b2", null).In(Db);
            new NumberType("a1", "b2", null).In(Db);
            new NumberType("a2", "b3", null).In(Db);

            var r = _controller.Search(null, "b").Data.ToArray();

            Assert.Equal(4, r.Count());
            Assert.Equal("a3", r[0].Key);
            Assert.Equal("a1", r[1].Key);
            Assert.Equal("a2", r[2].Key);
            Assert.Equal("b3", r[3].Value);
        }

        [Fact]
        public void ShouldReturnCorrectColumns()
        {
            var event1 = new Event(1) {Description = "Event 1"};
            var event2 = new Event(2) {Description = "Event 2"};
            var n1 = new NumberType("a3", "b", 1)
            {
                RelatedEvent = event1,
                IssuedByIpOffice = true
            }.In(Db);
            new NumberType("a2", "b2", 2)
            {
                RelatedEvent = event2,
                IssuedByIpOffice = false
            }.In(Db);
            new NumberType("a1", "b2", null).In(Db);
            new NumberType("a2", "b3", null).In(Db);

            var r = _controller.Search(null, "b").Data.ToArray();

            Assert.Equal(4, r.Count());
            Assert.Equal("a3", r[0].Key);
            Assert.Equal("a1", r[1].Key);
            Assert.Equal("a2", r[2].Key);
            Assert.Equal("b3", r[3].Value);

            Assert.Equal(event1.Description, r[0].RelatedEvent);
            Assert.Equal(n1.IssuedByIpOffice, r[0].IssuedByIpOffice);
        }

        [Fact]
        public void ShouldSearchForCode()
        {
            var id = new NumberType("a", "b", null).In(Db).NumberTypeCode;
            var r = _controller.Search(null, "a").Data;

            Assert.Equal(id, r.Single().Key);
        }

        [Fact]
        public void ShouldSearchForDescription()
        {
            var id = new NumberType("a", "b", null).In(Db).NumberTypeCode;
            var r = _controller.Search(null, "b").Data;

            Assert.Equal(id, r.Single().Key);
        }
    }
}