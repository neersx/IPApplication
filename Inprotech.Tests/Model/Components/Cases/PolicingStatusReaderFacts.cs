using System;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Policing;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases
{
    public class PolicingStatusReaderFacts : FactBase
    {
        public PolicingStatusReaderFacts()
        {
            _policingStatusReader = new PolicingStatusReader(Db);
        }

        readonly IPolicingStatusReader _policingStatusReader;

        [Theory]
        [InlineData(1)]
        [InlineData(2)]
        [InlineData(3)]
        [InlineData(4)]
        public void ShouldReturnError(int onHold)
        {
            BuildPolicing(1, Fixture.Today(), onHold).In(Db);
            BuildPolicingError(1, Fixture.FutureDate()).In(Db);

            Assert.Equal(PolicingStatusReader.Error, _policingStatusReader.Read(1));
        }

        [Theory]
        [InlineData(2)]
        [InlineData(3)]
        [InlineData(4)]
        public void ShouldReturnRunning(int onHold)
        {
            BuildPolicing(1, Fixture.Today(), onHold).In(Db);

            Assert.Equal(PolicingStatusReader.Running, _policingStatusReader.Read(1));
        }

        [Theory]
        [InlineData(0)]
        [InlineData(1)]
        public void ShouldReturnPending(int onHold)
        {
            BuildPolicing(1, Fixture.Today(), onHold).In(Db);

            Assert.Equal(PolicingStatusReader.Pending, _policingStatusReader.Read(1));
        }

        public static PolicingRequest BuildPolicing(int caseId, DateTime dateEntered, int onHold,
                                                    bool isSystemGenerated = true)
        {
            return new PolicingRequest
            {
                CaseId = caseId,
                DateEntered = dateEntered,
                OnHold = onHold,
                IsSystemGenerated = isSystemGenerated ? 1 : 0
            };
        }

        public static PolicingError BuildPolicingError(int caseId, DateTime startDateTime)
        {
            return new PolicingError
            {
                CaseId = caseId,
                StartDateTime = startDateTime
            };
        }

        [Fact]
        public void ErrorAndRunningHaveHigherPriorityThanPendingAndOnHold()
        {
            BuildPolicing(1, Fixture.Today(), 1).In(Db);
            BuildPolicingError(1, Fixture.FutureDate()).In(Db);
            BuildPolicing(1, Fixture.Today(), 0).In(Db);

            Assert.Equal(PolicingStatusReader.Error, _policingStatusReader.Read(1));
        }

        [Fact]
        public void ShouldReturnNull()
        {
            BuildPolicing(1, Fixture.Today(), 5).In(Db);

            Assert.Null(_policingStatusReader.Read(1));
        }

        [Fact]
        public void ShouldReturnNullIfNoMatchingPolicingRequestFound()
        {
            Assert.Null(_policingStatusReader.Read(1));
        }

        [Fact]
        public void ShouldReturnOnHold()
        {
            BuildPolicing(1, Fixture.Today(), 9).In(Db);

            Assert.Equal(PolicingStatusReader.OnHold, _policingStatusReader.Read(1));
        }

        [Fact]
        public void ShouldReturnStatusForMultipleCases()
        {
            BuildPolicing(1, Fixture.Today(), 2).In(Db);
            BuildPolicingError(1, Fixture.FutureDate()).In(Db); // case1 => error

            BuildPolicing(2, Fixture.Today(), 2).In(Db); // case2 => Running

            BuildPolicing(3, Fixture.Today(), 0).In(Db); // case3 => Pending

            BuildPolicing(4, Fixture.Today(), 9).In(Db); // case4 => OnHold

            var results = _policingStatusReader.ReadMany(new[] {1, 2, 3, 4, 5});

            Assert.Equal("Error", results[1]);
            Assert.Equal("Running", results[2]);
            Assert.Equal("Pending", results[3]);
            Assert.Equal("OnHold", results[4]);
            Assert.Null(results[5]);
        }

        [Fact]
        public void StatusShouldBeRunning_IfErrorCreatedDateIsEalierThanPolicingStarted()
        {
            BuildPolicing(1, Fixture.Today(), 2).In(Db);
            BuildPolicingError(1, Fixture.PastDate()).In(Db);

            Assert.Equal(PolicingStatusReader.Running, _policingStatusReader.Read(1));
        }
    }
}