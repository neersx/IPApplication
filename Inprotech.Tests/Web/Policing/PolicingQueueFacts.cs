using System;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Policing;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Policing.Monitoring;
using InprotechKaizen.Model.Policing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingQueueFacts
    {
        public class RetrieveMethod : FactBase
        {
            [Theory]
            [InlineData(PolicingItemStatus.WaitingToStart)]
            [InlineData(PolicingItemStatus.InProgress)]
            [InlineData(PolicingItemStatus.Error)]
            [InlineData(PolicingItemStatus.Failed)]
            [InlineData(PolicingItemStatus.OnHold)]
            [InlineData(PolicingItemStatus.Blocked)]
            public void ReturnsAll(string availableItemInViewWithStatus)
            {
                new PolicingQueueViewBuilder(Db)
                {
                    Status = availableItemInViewWithStatus
                }.Build();

                Assert.Single(new PolicingQueueFixture(Db).Subject.Retrieve(PolicingQueueKnownStatus.All));
            }

            [Theory]
            [InlineData(PolicingQueueKnownStatus.OnHold)]
            [InlineData(PolicingQueueKnownStatus.Progressing)]
            [InlineData(PolicingQueueKnownStatus.RequiresAttention)]
            public void ReturnsByRequiredStatusOnly(string knownStatus)
            {
                var item1 = new PolicingQueueViewBuilder(Db).SetRandomMappedStatus(knownStatus).Build();

                new PolicingQueueViewBuilder(Db)
                    .PickAnotherMappedStatusNotIn(knownStatus)
                    .Build();

                var r = new PolicingQueueFixture(Db).Subject.Retrieve(knownStatus).ToArray();

                Assert.Single(r);
                Assert.Equal(item1.RequestId, r.Single().RequestId);
            }

            [Fact]
            public void ResolvesForPreferredCulture()
            {
                var f = new PolicingQueueFixture(Db);

                f.Subject.Retrieve(PolicingQueueKnownStatus.All);

                f.PreferredCultureResolver.Received(1).Resolve();
            }

            [Fact]
            public void ReturnsPolicingQueueItem()
            {
#pragma warning disable 618
                var p = new PolicingQueueView
#pragma warning restore 618
                {
                    Requested = Fixture.Today(),
                    Status = PolicingItemStatus.WaitingToStart,
                    User = Fixture.String(),
                    UserKey = Fixture.String(),
                    CaseId = Fixture.Integer(),
                    CaseReference = Fixture.String(),
                    EventId = Fixture.Integer(),
                    CriteriaId = Fixture.Integer(),
                    TypeOfRequest = Fixture.String(),
                    IdleFor = Fixture.Integer(),
                    Jurisdiction = Fixture.String(),
                    PropertyName = Fixture.String(),
                    EventDescription = Fixture.String()
                }.In(Db);

                var r = new PolicingQueueFixture(Db).Subject.Retrieve(PolicingQueueKnownStatus.All).Single();

                Assert.Equal(p.Requested, r.Requested);
                Assert.Equal(p.RequestId, r.RequestId);
                Assert.Equal(p.Status, r.Status);
                Assert.Equal(p.User, r.User);
                Assert.Equal(p.UserKey, r.UserKey);
                Assert.Equal(p.CaseId, r.CaseId);
                Assert.Equal(p.CaseReference, r.CaseReference);
                Assert.Equal(p.EventId, r.EventId);
                Assert.Equal(p.CriteriaId, r.CriteriaId);
                Assert.Equal(p.TypeOfRequest, r.TypeOfRequest);
                Assert.Equal(p.IdleFor, r.IdleFor);
                Assert.Equal(p.Jurisdiction, r.Jurisdiction);
                Assert.Equal(p.PropertyName, r.PropertyName);
                Assert.Equal(p.EventDescription, r.EventDescription);
            }

            [Fact]
            public void ThrowsIfStatusProvidedIsNotSupportedForFiltering()
            {
                // ReSharper disable once ReturnValueOfPureMethodIsNotUsed
                Assert.Throws<NotSupportedException>(() => { new PolicingQueueFixture(Db).Subject.Retrieve(Fixture.String()).ToArray(); });
            }
        }

        public class PolicingQueueItemFacts
        {
            [Fact]
            public void DefaultsToBasicActionName()
            {
                var p = new PolicingQueueItem
                {
                    SpecificActionName = null,
                    DefaultActionName = "B"
                };

                Assert.Equal("B", p.ActionName);
            }

            [Fact]
            public void DefaultsToBasicEventDescription()
            {
                var p = new PolicingQueueItem
                {
                    SpecificEventDescription = null,
                    DefaultEventDescription = "B"
                };

                Assert.Equal("B", p.EventDescription);
            }

            [Fact]
            public void SpecificActionNameTakesPrecedenceOverBasicActionName()
            {
                var p = new PolicingQueueItem
                {
                    SpecificActionName = "A",
                    DefaultActionName = "B"
                };

                Assert.Equal("A", p.ActionName);
            }

            [Fact]
            public void SpecificEventDescriptionTakesPrecedenceOverBasicDescription()
            {
                var p = new PolicingQueueItem
                {
                    SpecificEventDescription = "A",
                    DefaultEventDescription = "B"
                };

                Assert.Equal("A", p.EventDescription);
            }
        }

        public class AllowableFiltersMethod : FactBase
        {
            [Theory]
            [InlineData("user")]
            [InlineData("caseReference")]
            [InlineData("status")]
            [InlineData("typeOfRequest")]
            public void ThrowsIfStatusProvidedIsNotSupportedForFiltering(string field)
            {
                Assert.Throws<NotSupportedException>(() => { new PolicingQueueFixture(Db).Subject.AllowableFilters(Fixture.String(), field, new CommonQueryParameters()); });
            }

            [Theory]
            [InlineData(PolicingQueueKnownStatus.All)]
            [InlineData(PolicingQueueKnownStatus.OnHold)]
            [InlineData(PolicingQueueKnownStatus.Progressing)]
            [InlineData(PolicingQueueKnownStatus.RequiresAttention)]
            public void ThrowsIfFieldProvidedIsNotSupportedForFiltering(string byStatus)
            {
                Assert.Throws<NotSupportedException>(() => { new PolicingQueueFixture(Db).Subject.AllowableFilters(byStatus, Fixture.String(), new CommonQueryParameters()); });
            }

            [Theory]
            [InlineData(PolicingQueueKnownStatus.OnHold)]
            [InlineData(PolicingQueueKnownStatus.Progressing)]
            [InlineData(PolicingQueueKnownStatus.RequiresAttention)]
            public void ReturnsDistinctFilterableOptionsForUsers(string knownStatus)
            {
                new PolicingQueueViewBuilder(Db)
                {
                    User = "a",
                    UserKey = "a-key"
                }.SetRandomMappedStatus(knownStatus).Build();

                new PolicingQueueViewBuilder(Db)
                {
                    User = "b",
                    UserKey = "b-key"
                }.SetRandomMappedStatus(knownStatus).Build();

                new PolicingQueueViewBuilder(Db)
                    {
                        User = "c",
                        UserKey = "c-key"
                    }
                    .PickAnotherMappedStatusNotIn(knownStatus)
                    .Build();

                new PolicingQueueViewBuilder(Db)
                {
                    User = "a",
                    UserKey = "a-key"
                }.SetRandomMappedStatus(knownStatus).Build();

                var r = new PolicingQueueFixture(Db).Subject.AllowableFilters(knownStatus, "user", new CommonQueryParameters()).ToArray();

                Assert.Equal(2, r.Length);

                Assert.Equal("a-key", r[0].Code);
                Assert.Equal("b-key", r[1].Code);

                Assert.Equal("a", r[0].Description);
                Assert.Equal("b", r[1].Description);
            }

            [Theory]
            [InlineData(PolicingQueueKnownStatus.OnHold)]
            [InlineData(PolicingQueueKnownStatus.Progressing)]
            [InlineData(PolicingQueueKnownStatus.RequiresAttention)]
            public void ReturnsDistinctFilterableOptionsForCaseReference(string knownStatus)
            {
                new PolicingQueueViewBuilder(Db)
                {
                    CaseRef = "123"
                }.SetRandomMappedStatus(knownStatus).Build();

                new PolicingQueueViewBuilder(Db)
                {
                    CaseRef = "456"
                }.SetRandomMappedStatus(knownStatus).Build();

                new PolicingQueueViewBuilder(Db)
                    {
                        CaseRef = "789"
                    }
                    .PickAnotherMappedStatusNotIn(knownStatus)
                    .Build();

                new PolicingQueueViewBuilder(Db)
                {
                    CaseRef = "123"
                }.SetRandomMappedStatus(knownStatus).Build();

                var r = new PolicingQueueFixture(Db).Subject.AllowableFilters(knownStatus, "caseReference", new CommonQueryParameters()).ToArray();

                Assert.Equal(2, r.Length);

                Assert.Equal("123", r[0].Code);
                Assert.Equal("456", r[1].Code);

                Assert.Equal("123", r[0].Description); /* case ref is compared rather than case id */
                Assert.Equal("456", r[1].Description); /* case ref is compared rather than case id */
            }

            [Fact]
            public void ReturnsDistinctFilterableOptionsForStatuses()
            {
                new PolicingQueueViewBuilder(Db)
                {
                    Status = PolicingItemStatus.WaitingToStart
                }.Build();

                new PolicingQueueViewBuilder(Db)
                {
                    Status = PolicingItemStatus.Error
                }.Build();

                new PolicingQueueViewBuilder(Db)
                    {
                        Status = PolicingItemStatus.OnHold
                    }
                    .Build();

                new PolicingQueueViewBuilder(Db)
                {
                    Status = PolicingItemStatus.OnHold
                }.Build();

                var r = new PolicingQueueFixture(Db).Subject.AllowableFilters("all", "status", new CommonQueryParameters()).ToArray();

                Assert.Equal(3, r.Length);

                Assert.Equal(PolicingItemStatus.Error, r[0].Code);
                Assert.Equal(PolicingItemStatus.OnHold, r[1].Code);
                Assert.Equal(PolicingItemStatus.WaitingToStart, r[2].Code);

                Assert.Equal(PolicingItemStatus.Error, r[0].Description); /* case ref is compared rather than case id */
                Assert.Equal(PolicingItemStatus.OnHold, r[1].Description); /* case ref is compared rather than case id */
                Assert.Equal(PolicingItemStatus.WaitingToStart, r[2].Description); /* case ref is compared rather than case id */
            }

            [Fact]
            public void ReturnsFilteredByUserThroughCommonQueryService()
            {
                new PolicingQueueViewBuilder(Db)
                {
                    Status = "waiting-to-start",
                    User = "a",
                    UserKey = "a-key"
                }.Build();

                new PolicingQueueViewBuilder(Db)
                {
                    Status = "waiting-to-start",
                    User = "b",
                    UserKey = "b-key"
                }.Build();

                var cultureResolver = Substitute.For<IPreferredCultureResolver>();
                var subject = new PolicingQueue(Db, cultureResolver, new CommonQueryService());

                var qp = new CommonQueryParameters
                {
                    Filters = new[]
                    {
                        new CommonQueryParameters.FilterValue
                        {
                            Field = "userKey",
                            Operator = "in",
                            Value = "a-key"
                        }
                    }
                };

                var r = subject.AllowableFilters("all", "status", qp);

                Assert.NotNull(r.Single());
            }
        }

        public class PolicingQueueFixture : IFixture<PolicingQueue>
        {
            public PolicingQueueFixture(InMemoryDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                CommonQueryService = Substitute.For<ICommonQueryService>();
                CommonQueryService.Filter(Arg.Any<IDbSet<PolicingQueueView>>(), Arg.Any<CommonQueryParameters>())
                                  .Returns(x => x[0]);

                Subject = new PolicingQueue(db, PreferredCultureResolver, CommonQueryService);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public ICommonQueryService CommonQueryService { get; set; }

            public PolicingQueue Subject { get; }
        }
    }
}