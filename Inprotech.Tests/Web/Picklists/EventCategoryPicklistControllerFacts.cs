using System;
using System.Linq;
using System.Reflection;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Picklists.ResponseShaping;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class EventCategoryPicklistControllerFacts : FactBase
    {
        public class SearchMethod : FactBase
        {
            void EventCategories(string searchText = "", bool withExactMatch = false)
            {
                if (withExactMatch)
                {
                    new InprotechKaizen.Model.Cases.Events.EventCategory(Fixture.Short())
                    {
                        Name = searchText,
                        Description = Fixture.String(),
                        IconImage = new Image(Fixture.Integer())
                        {
                            ImageData = Fixture.RandomBytes(1),
                            Detail = new ImageDetail
                            {
                                ImageDescription = Fixture.String(),
                                ImageStatus = ProtectedTableCode.EventCategoryImageStatus
                            }
                        }
                    }.In(Db);
                }

                new InprotechKaizen.Model.Cases.Events.EventCategory(Fixture.Short())
                {
                    Name = Fixture.String(searchText),
                    Description = Fixture.String(),
                    IconImage = new Image(Fixture.Integer())
                    {
                        ImageData = Fixture.RandomBytes(1),
                        Detail = new ImageDetail
                        {
                            ImageDescription = Fixture.String(),
                            ImageStatus = ProtectedTableCode.EventCategoryImageStatus
                        }
                    }
                }.In(Db);
                new InprotechKaizen.Model.Cases.Events.EventCategory(Fixture.Short())
                {
                    Name = Fixture.String() + searchText,
                    Description = Fixture.String(),
                    IconImage = new Image(Fixture.Integer())
                    {
                        ImageData = Fixture.RandomBytes(1),
                        Detail = new ImageDetail
                        {
                            ImageDescription = Fixture.String(),
                            ImageStatus = ProtectedTableCode.EventCategoryImageStatus
                        }
                    }
                }.In(Db);
                new InprotechKaizen.Model.Cases.Events.EventCategory(Fixture.Short())
                {
                    Name = "A",
                    Description = Fixture.String(),
                    IconImage = new Image(Fixture.Integer())
                    {
                        ImageData = Fixture.RandomBytes(1),
                        Detail = new ImageDetail
                        {
                            ImageDescription = Fixture.String(),
                            ImageStatus = ProtectedTableCode.EventCategoryImageStatus
                        }
                    }
                }.In(Db);
            }

            [Fact]
            public void ReturnsAllEventCategories()
            {
                EventCategories();
                var f = new EventCategoryPicklistControllerFixture(Db);
                var r = f.Subject.Search(f.DefaultQueryParameter, null);

                Assert.Equal(3, r.Data.Count());
            }

            [Fact]
            public void ReturnsItemsContainingExactMatch()
            {
                var search = Fixture.String();
                EventCategories(search, true);
                var f = new EventCategoryPicklistControllerFixture(Db);
                var r = f.Subject.Search(new CommonQueryParameters(), search);

                Assert.Equal(3, r.Data.Count());
                Assert.Equal(search, ((EventCategory) r.Data.First()).Name);
            }

            [Fact]
            public void ReturnsItemsContainingSearchText()
            {
                var search = Fixture.String();
                EventCategories(search);
                var f = new EventCategoryPicklistControllerFixture(Db);
                var r = f.Subject.Search(f.DefaultQueryParameter, search);

                Assert.Equal(2, r.Data.Count());
            }

            [Fact]
            public void ReturnsItemsOrderedByName()
            {
                var search = Fixture.String();
                EventCategories(search, true);
                var f = new EventCategoryPicklistControllerFixture(Db);
                var r = f.Subject.Search(f.DefaultQueryParameter, search);

                Assert.Equal(3, r.Data.Count());
                Assert.True(r.Data.OfType<EventCategory>().IsOrdered(x => x.Name));
            }
        }

        public class Maintenance : FactBase
        {
            [Fact]
            public void AddsNewEventCategory()
            {
                var e = new EventCategory
                {
                    Name = Fixture.String(),
                    Description = Fixture.String(),
                    ImageData = new ImageModel
                    {
                        Key = Fixture.Integer()
                    }
                };
                var f = new EventCategoryPicklistControllerFixture(Db);
                f.Subject.AddOrDuplicate(e);
                f.EventCategoryMaintenance.Received(1).Save(e, Operation.Add);
                f.EventCategoryMaintenance.DidNotReceive().Save(Arg.Any<EventCategory>(), Operation.Update);
                f.EventCategoryMaintenance.DidNotReceive().Delete(Arg.Any<short>());
            }

            [Fact]
            public void DeletesExistingEventCategory()
            {
                var key = Fixture.Integer();
                var f = new EventCategoryPicklistControllerFixture(Db);
                f.Subject.Delete(key);
                f.EventCategoryMaintenance.Received(1).Delete(key);
                f.EventCategoryMaintenance.DidNotReceive().Save(Arg.Any<EventCategory>(), Arg.Any<Operation>());
            }

            [Fact]
            public void UpdatesExistingTableCode()
            {
                var id = Fixture.Short();
                var e = new EventCategory
                {
                    Key = id,
                    Name = Fixture.String(),
                    Description = Fixture.String(),
                    ImageData = new ImageModel
                    {
                        Key = Fixture.Integer()
                    }
                };
                var f = new EventCategoryPicklistControllerFixture(Db);
                f.Subject.Update(id, e);
                f.EventCategoryMaintenance.Received(1).Save(e, Operation.Update);
                f.EventCategoryMaintenance.DidNotReceive().Save(Arg.Any<EventCategory>(), Operation.Add);
                f.EventCategoryMaintenance.DidNotReceive().Delete(Arg.Any<short>());
            }
        }

        public class EventCategoryPicklistControllerFixture : IFixture<EventCategoryPicklistController>
        {
            public EventCategoryPicklistControllerFixture(InMemoryDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                EventCategoryMaintenance = Substitute.For<IEventCategoryPicklistMaintenance>();
                Subject = new EventCategoryPicklistController(db, PreferredCultureResolver, EventCategoryMaintenance);
                DefaultQueryParameter = new CommonQueryParameters
                {
                    SortBy = "Name"
                };
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public IEventCategoryPicklistMaintenance EventCategoryMaintenance { get; set; }

            public CommonQueryParameters DefaultQueryParameter { get; set; }

            public EventCategoryPicklistController Subject { get; }
        }
    }

    public class EventCategoryItemFacts
    {
        readonly Type _subject = typeof(EventCategory);

        [Fact]
        public void DisplaysFollowingFields()
        {
            Assert.Equal(new[] {"Name", "Description", "Image", "ImageDescription"},
                         _subject.DisplayableFields());
        }

        [Fact]
        public void PicklistCodeIsDefined()
        {
            Assert.NotNull(_subject
                           .GetProperty("Name").GetCustomAttribute<PicklistCodeAttribute>());
        }

        [Fact]
        public void PicklistDescriptionIsDefined()
        {
            Assert.NotNull(_subject
                           .GetProperty("Description").GetCustomAttribute<PicklistDescriptionAttribute>());
        }

        [Fact]
        public void PicklistKeyIsDefined()
        {
            Assert.NotNull(_subject
                           .GetProperty("Key").GetCustomAttribute<PicklistKeyAttribute>());
        }

        [Fact]
        public void SortableFields()
        {
            Assert.Equal(new[] {"Name", "Description", "ImageDescription"},
                         _subject.SortableFields());
        }
    }
}