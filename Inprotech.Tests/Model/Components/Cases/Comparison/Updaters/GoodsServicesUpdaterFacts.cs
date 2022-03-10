using System;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Cases.Comparison.Builders;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Comparison.Updaters;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;
using GoodsServices = InprotechKaizen.Model.Components.Cases.Comparison.Results.GoodsServices;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Updaters
{
    public class GoodsServicesUpdaterFacts
    {
        public class UpdateMethod : FactBase
        {
            [Fact]
            public void AddsLocalClass()
            {
                var @case = new InprotechCaseBuilder(Db)
                    .Build();

                var comparedGoodsServices = new GoodsServices
                {
                    Class = new Value<string>().AsUpdatedValue("09", "09")
                };

                var f = new GoodsServicesUpdaterFixture(Db)
                    .WithExistingLocalClass();

                f.Subject.Update(@case, new[] {comparedGoodsServices});

                f.GoodsServices.Received(1).DoesClassExists(Arg.Is(@case), Arg.Is(comparedGoodsServices.Class.TheirValue));

                f.GoodsServices.Received(0).AddClass(Arg.Is(@case), Arg.Is(comparedGoodsServices.Class.TheirValue));
            }

            [Fact]
            public void CallsUpdateMethod()
            {
                var @case = new InprotechCaseBuilder(Db)
                            .WithClass("09", "09")
                            .Build();

                var comparedGoodsServices = new GoodsServices
                {
                    Class = new Value<string>().AsUpdatedValue("09", "009"),
                    Text = new Value<string>().AsUpdatedValue("old", "new"),
                    FirstUsedDate = new FirstUsedDate
                    {
                        OurValue = Fixture.PastDate(),
                        TheirValue = Fixture.FutureDate(),
                        Different = true,
                        Updated = true
                    },
                    FirstUsedDateInCommerce = new FirstUsedDate
                    {
                        OurValue = Fixture.PastDate(),
                        TheirValue = Fixture.FutureDate(),
                        Different = true,
                        Updated = true
                    }
                };

                var f = new GoodsServicesUpdaterFixture(Db)
                    .WithExistingLocalClass();

                f.Subject.Update(@case, new[] {comparedGoodsServices});

                f.GoodsServices.Received(1).AddOrUpdate(Arg.Is(@case), Arg.Is("09"), Arg.Is("new"), Arg.Is((int?) null), Arg.Is(Fixture.FutureDate()), Arg.Is(Fixture.FutureDate()));
            }

            [Fact]
            public void CallsUpdateMethodWithRequiredParams()
            {
                var @case = new InprotechCaseBuilder(Db)
                    .Build();

                var comparedGoodsServices = new GoodsServices
                {
                    Class = new Value<string>().AsUpdatedValue("09", "09"),
                    FirstUsedDateInCommerce = new FirstUsedDate
                    {
                        OurValue = Fixture.PastDate(),
                        TheirValue = Fixture.FutureDate(),
                        Different = true,
                        Updated = true
                    }
                };

                var f = new GoodsServicesUpdaterFixture(Db)
                    .WithExistingLocalClass();

                f.Subject.Update(@case, new[] {comparedGoodsServices});

                f.GoodsServices.Received(1).AddOrUpdate(Arg.Is(@case), Arg.Is("09"), Arg.Is((string) null), Arg.Is((int?) null), Arg.Is((DateTime?) null), Arg.Is(Fixture.FutureDate()));
            }

            [Fact]
            public void UsesExistingLocalClass()
            {
                var @case = new InprotechCaseBuilder(Db)
                    .Build();

                var comparedGoodsServices = new GoodsServices
                {
                    Class = new Value<string>().AsUpdatedValue(null, "09")
                };

                var f = new GoodsServicesUpdaterFixture(Db)
                        .WithExistingLocalClass(false)
                        .WithLocalClassAdded("09");

                f.Subject.Update(@case, new[] {comparedGoodsServices});

                f.GoodsServices.Received(1).DoesClassExists(Arg.Is(@case), Arg.Is(comparedGoodsServices.Class.TheirValue));

                f.GoodsServices.Received(1).AddClass(Arg.Is(@case), Arg.Is(comparedGoodsServices.Class.TheirValue));
            }
        }
    }

    internal class GoodsServicesUpdaterFixture : IFixture<IGoodsServicesUpdater>
    {
        public GoodsServicesUpdaterFixture(InMemoryDbContext db)
        {
            GoodsServices = Substitute.For<IGoodsServices>();

            Subject = new GoodsServicesUpdater(db, GoodsServices);
        }

        public IGoodsServices GoodsServices { get; }
        public IGoodsServicesUpdater Subject { get; }

        public GoodsServicesUpdaterFixture WithExistingLocalClass(bool exists = true)
        {
            GoodsServices.DoesClassExists(Arg.Any<Case>(), Arg.Any<string>()).Returns(exists);

            return this;
        }

        public GoodsServicesUpdaterFixture WithLocalClassAdded(string classId)
        {
            GoodsServices.AddClass(Arg.Any<Case>(), Arg.Any<string>()).Returns(classId);

            return this;
        }
    }
}