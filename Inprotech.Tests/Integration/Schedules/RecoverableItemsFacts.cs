using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.Schedules;
using NSubstitute;
using Xunit;

#pragma warning disable CS0612 
#pragma warning disable CS0618

namespace Inprotech.Tests.Integration.Schedules
{
    public class RecoverableItemsFacts : FactBase
    {
        [Fact]
        public void CallsSceduleRecoveryReader()
        {
            var failedItems = new[]
            {
                new FailedItem {ApplicationNumber = "A1", ArtifactId = 1, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"}
            };
            var f = new RecoverableItemsFixture()
                .WithScheduleRecoverables(failedItems);

            var r = f.Subject.FindBySchedule(1).Single();

            Assert.False(r.IsEmpty);
            f._scheduleRecoverableReader.ReceivedWithAnyArgs(1).GetAll();
            f._scheduleRecoverableReader.ReceivedWithAnyArgs(1).OrphanDocuments(Arg.Any<IEnumerable<FailedItem>>(), OrphanDocumentsReaderMode.ForRecovery, out _);
        }

        [Fact]
        public void CallsSceduleRecoveryReaderGetByDataSourceType()
        {
            var failedItems = new[]
            {
                new FailedItem {ApplicationNumber = "A1", ArtifactId = 1, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*", DataSourceType = DataSourceType.UsptoPrivatePair},
                new FailedItem {ApplicationNumber = "A2", ArtifactId = 2, ArtifactType = ArtifactType.Case, ScheduleId = 2, CorrelationId = "*", DataSourceType = DataSourceType.IpOneData}
            };
            var f = new RecoverableItemsFixture()
                .WithScheduleRecoverables(failedItems);

            var r = f.Subject.FindByDataType(DataSourceType.UsptoPrivatePair).Single();

            Assert.False(r.IsEmpty);
            f._scheduleRecoverableReader.ReceivedWithAnyArgs(1).GetAll();
            f._scheduleRecoverableReader.ReceivedWithAnyArgs(1).OrphanDocuments(Arg.Any<IEnumerable<FailedItem>>(), OrphanDocumentsReaderMode.ForRecovery, out _);
        }

        [Fact]
        public void CaseIdsShouldBeUnique()
        {
            var failedItems = new[]
            {
                new FailedItem {Id = 1, ArtifactId = 1, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"},
                new FailedItem {Id = 2, ArtifactId = 1, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"},
                new FailedItem {Id = 3, ArtifactId = 1, ArtifactType = ArtifactType.Document, ScheduleId = 1, CorrelationId = "*"}
            };

            var f = new RecoverableItemsFixture()
                .WithScheduleRecoverables(failedItems);

            var r = f.Subject.FindBySchedule(1).Single();

            Assert.Single(r.CaseIds);
            Assert.Equal(3, r.ScheduleRecoverableIds.Count());
            Assert.Single(r.DocumentIds);
        }

        [Fact]
        public void CaseIdsShouldBeUniqueGetByDataSourceType()
        {
            var failedItems = new[]
            {
                new FailedItem {Id = 1, ArtifactId = 1, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*", DataSourceType = DataSourceType.UsptoPrivatePair},
                new FailedItem {Id = 2, ArtifactId = 1, ArtifactType = ArtifactType.Case, ScheduleId = 2, CorrelationId = "*", DataSourceType = DataSourceType.UsptoPrivatePair},
                new FailedItem {Id = 3, ArtifactId = 1, ArtifactType = ArtifactType.Document, ScheduleId = 3, CorrelationId = "*", DataSourceType = DataSourceType.UsptoPrivatePair}
            };

            var f = new RecoverableItemsFixture()
                .WithScheduleRecoverables(failedItems);

            var r = f.Subject.FindByDataType(DataSourceType.UsptoPrivatePair).Single();

            Assert.Single(r.CaseIds);
            Assert.Equal(3, r.ScheduleRecoverableIds.Count());
            Assert.Single(r.DocumentIds);
        }

        [Fact]
        public void CorrelatedIdShouldBeNullIfUnused()
        {
            var failedItems = new[]
            {
                new FailedItem {ArtifactId = 1, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"}
            };

            var f = new RecoverableItemsFixture()
                .WithScheduleRecoverables(failedItems);

            var r = f.Subject.FindBySchedule(1).Single();
            Assert.Null(r.CorrelationId);
        }

        [Fact]
        public void CorrelatedIdShouldBeNullIfUnusedGetByDataSourceType()
        {
            var failedItems = new[]
            {
                new FailedItem {ArtifactId = 1, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*", DataSourceType = DataSourceType.IpOneData}
            };

            var f = new RecoverableItemsFixture()
                .WithScheduleRecoverables(failedItems);

            var r = f.Subject.FindByDataType(DataSourceType.IpOneData).Single();
            Assert.Null(r.CorrelationId);
        }

        [Fact]
        public void DerivesFromScheduleRecoverableCases()
        {
            var failedItems = new[]
            {
                new FailedItem {Id = 1, ApplicationNumber = "A1", ArtifactId = 1, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"},
                new FailedItem {Id = 2, ApplicationNumber = "A2", ArtifactId = 2, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"}
            };
            var f = new RecoverableItemsFixture()
                .WithScheduleRecoverables(failedItems);

            var r = f.Subject.FindBySchedule(1).Single();

            Assert.False(r.IsEmpty);
            Assert.Equal(2, r.CaseIds.Count());
            Assert.Equal(2, r.ScheduleRecoverableIds.Count());
            Assert.Empty(r.DocumentIds);
        }

        [Fact]
        public void DerivesFromScheduleRecoverableCasesGetByDataSourceType()
        {
            var failedItems = new[]
            {
                new FailedItem {Id = 1, ApplicationNumber = "A1", ArtifactId = 1, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"},
                new FailedItem {Id = 2, ApplicationNumber = "A2", ArtifactId = 2, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"}
            };
            var f = new RecoverableItemsFixture()
                .WithScheduleRecoverables(failedItems);

            var r = f.Subject.FindByDataType(DataSourceType.UsptoPrivatePair).Single();

            Assert.False(r.IsEmpty);
            Assert.Equal(2, r.CaseIds.Count());
            Assert.Equal(2, r.ScheduleRecoverableIds.Count());
            Assert.Empty(r.DocumentIds);
        }

        [Fact]
        public void DerivesFromScheduleRecoverableDocuments()
        {
            var failedItems = new[]
            {
                new FailedItem {Id = 1, ArtifactId = 1, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"},
                new FailedItem {Id = 2, ArtifactId = 2, ArtifactType = ArtifactType.Document, ScheduleId = 1, CorrelationId = "*"}
            };

            var f = new RecoverableItemsFixture()
                .WithScheduleRecoverables(failedItems);

            var r = f.Subject.FindBySchedule(1).Single();

            Assert.Single(r.CaseIds);
            Assert.Equal(2, r.ScheduleRecoverableIds.Count());
            Assert.Single(r.DocumentIds);
        }

        [Fact]
        public void DerivesFromScheduleRecoverableDocumentsGetByDataSourceType()
        {
            var failedItems = new[]
            {
                new FailedItem {Id = 1, ArtifactId = 1, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"},
                new FailedItem {Id = 2, ArtifactId = 2, ArtifactType = ArtifactType.Document, ScheduleId = 10, CorrelationId = "*"}
            };

            var f = new RecoverableItemsFixture()
                .WithScheduleRecoverables(failedItems);

            var r = f.Subject.FindByDataType(DataSourceType.UsptoPrivatePair).Single();

            Assert.Single(r.CaseIds);
            Assert.Equal(2, r.ScheduleRecoverableIds.Count());
            Assert.Single(r.DocumentIds);
        }

        [Fact]
        public void DocumentIdsShouldBeUnique()
        {
            var failedItems = new[]
            {
                new FailedItem {Id = 1, ArtifactId = 1, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"},
                new FailedItem {Id = 2, ArtifactId = 2, ArtifactType = ArtifactType.Document, ScheduleId = 1, CorrelationId = "*"},
                new FailedItem {Id = 3, ArtifactId = 2, ArtifactType = ArtifactType.Document, ScheduleId = 1, CorrelationId = "*"}
            };

            var f = new RecoverableItemsFixture()
                .WithScheduleRecoverables(failedItems);

            var r = f.Subject.FindBySchedule(1).Single();

            Assert.Single(r.CaseIds);
            Assert.Equal(3, r.ScheduleRecoverableIds.Count());
            Assert.Single(r.DocumentIds);
        }

        [Fact]
        public void DocumentIdsShouldBeUniqueGetByDataSourceType()
        {
            var failedItems = new[]
            {
                new FailedItem {Id = 1, ArtifactId = 1, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"},
                new FailedItem {Id = 2, ArtifactId = 2, ArtifactType = ArtifactType.Document, ScheduleId = 1, CorrelationId = "*"},
                new FailedItem {Id = 3, ArtifactId = 2, ArtifactType = ArtifactType.Document, ScheduleId = 13, CorrelationId = "*"}
            };

            var f = new RecoverableItemsFixture()
                .WithScheduleRecoverables(failedItems);

            var r = f.Subject.FindByDataType(DataSourceType.UsptoPrivatePair).Single();

            Assert.Single(r.CaseIds);
            Assert.Equal(3, r.ScheduleRecoverableIds.Count());
            Assert.Single(r.DocumentIds);
        }

        [Fact]
        public void IncludeFailedItemWithoutArtifactId()
        {
            var failedItems = new[]
            {
                new FailedItem {Id = 1, ApplicationNumber = "A1", ArtifactId = 1, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"},
                new FailedItem {Id = 2, ApplicationNumber = "A2", ArtifactId = 2, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"},
                new FailedItem {Id = 3, ApplicationNumber = "A3", ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"}
            };
            var f = new RecoverableItemsFixture()
                .WithScheduleRecoverables(failedItems);

            var r = f.Subject.FindBySchedule(1).Single();

            Assert.False(r.IsEmpty);
            Assert.Equal(2, r.CaseIds.Count());
            Assert.Equal(1, r.CaseWithoutArtifactId.Count());
            Assert.Equal(3, r.ScheduleRecoverableIds.Count());
            Assert.Empty(r.DocumentIds);
        }

        [Fact]
        public void IncludeFailedItemWithoutArtifactIdGetByDataSourceType()
        {
            var failedItems = new[]
            {
                new FailedItem {Id = 1, ApplicationNumber = "A1", ArtifactId = 1, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"},
                new FailedItem {Id = 2, ApplicationNumber = "A2", ArtifactId = 2, ArtifactType = ArtifactType.Case, ScheduleId = 2, CorrelationId = "*"},
                new FailedItem {Id = 3, ApplicationNumber = "A3", ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "*"}
            };
            var f = new RecoverableItemsFixture()
                .WithScheduleRecoverables(failedItems);

            var r = f.Subject.FindByDataType(DataSourceType.UsptoPrivatePair).Single();

            Assert.False(r.IsEmpty);
            Assert.Equal(2, r.CaseIds.Count());
            Assert.Equal(1, r.CaseWithoutArtifactId.Count());
            Assert.Equal(3, r.ScheduleRecoverableIds.Count());
            Assert.Empty(r.DocumentIds);
        }

        [Fact]
        public void OneRecoveryInfoForEachCorrelatedId()
        {
            const int caseIdFrom12345 = 1;
            const int caseIdFrom45678 = 2;

            var failedItems = new[]
            {
                new FailedItem {ArtifactId = caseIdFrom12345, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "12345"},
                new FailedItem {ArtifactId = caseIdFrom45678, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "45678"}
            };

            var f = new RecoverableItemsFixture()
                .WithScheduleRecoverables(failedItems);

            var r = f.Subject.FindBySchedule(1).ToArray();

            Assert.False(r.IsEmpty());

            Assert.Equal("12345", r.First().CorrelationId);
            Assert.Equal(caseIdFrom12345, r.First().CaseIds.Single());

            Assert.Equal("45678", r.Last().CorrelationId);
            Assert.Equal(caseIdFrom45678, r.Last().CaseIds.Single());
        }

        [Fact]
        public void OneRecoveryInfoForEachCorrelatedIdGetByDataSourceType()
        {
            const int caseIdFrom12345 = 1;
            const int caseIdFrom45678 = 2;

            var failedItems = new[]
            {
                new FailedItem {ArtifactId = caseIdFrom12345, ArtifactType = ArtifactType.Case, ScheduleId = 1, CorrelationId = "12345"},
                new FailedItem {ArtifactId = caseIdFrom45678, ArtifactType = ArtifactType.Case, ScheduleId = 2, CorrelationId = "45678"}
            };

            var f = new RecoverableItemsFixture()
                .WithScheduleRecoverables(failedItems);

            var r = f.Subject.FindByDataType(DataSourceType.UsptoPrivatePair).ToArray();

            Assert.False(r.IsEmpty());

            Assert.Equal("12345", r.First().CorrelationId);
            Assert.Equal(caseIdFrom12345, r.First().CaseIds.Single());

            Assert.Equal("45678", r.Last().CorrelationId);
            Assert.Equal(caseIdFrom45678, r.Last().CaseIds.Single());
        }
    }

    public class RecoverableItemsFixture : IFixture<IRecoverableItems>
    {
        public readonly IScheduleRecoverableReader _scheduleRecoverableReader;

        public RecoverableItemsFixture()
        {
            _scheduleRecoverableReader = Substitute.For<IScheduleRecoverableReader>();

            Subject = new RecoverableItems(_scheduleRecoverableReader);

            _scheduleRecoverableReader.OrphanDocuments(Arg.Any<IEnumerable<FailedItem>>(), OrphanDocumentsReaderMode.ForRecovery, out _)
                                      .Returns(Enumerable.Empty<FailedItem>())
                                      .AndDoes(x => { });
        }

        public IRecoverableItems Subject { get; }

        public RecoverableItemsFixture WithScheduleRecoverables(IEnumerable<FailedItem> items)
        {
            _scheduleRecoverableReader.GetAll().Returns(items.AsQueryable());

            return this;
        }
    }
}