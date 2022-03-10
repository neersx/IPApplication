using System;
using System.Collections.Generic;
using Inprotech.Tests.Web.Builders;
using Inprotech.Web.Policing;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Policing.Monitoring;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class DashboardDataProviderFacts
    {
        public class RetrieveWithTrendMethod
        {
            readonly ISummaryReader _summaryReader = Substitute.For<ISummaryReader>();
            readonly ILogReader _logReader = Substitute.For<ILogReader>();
            readonly DetailBuilder _detailBuilder = new DetailBuilder();

            const RetrieveOption Option = RetrieveOption.WithTrends;

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ShouldReturnAvailability(bool hasHistoricalData)
            {
                _summaryReader.Read().Returns(new Summary());
                PolicingRateItem[] result;
                _logReader.IsHistoricalDataAvailable().Returns(hasHistoricalData);
                _logReader.TryGetRateGraphData(out result).ReturnsForAnyArgs(x =>
                {
                    x[0] = new PolicingRateItem[0];
                    return true;
                });

                var r = new DashboardDataProvider(_summaryReader, _logReader).Retrieve(Option)[Option];

                Assert.Equal(hasHistoricalData, r.Trend.HistoricalDataAvailable);
            }

            [Fact]
            public void ShouldReturnRateGraphData()
            {
                var rateGraphData = new[]
                {
                    new PolicingRateItem {EnterQueue = 1, ExitQueue = 1, TimeSlot = new DateTime()}
                };

                PolicingRateItem[] result;
                _summaryReader.Read().Returns(new Summary());
                _logReader.IsHistoricalDataAvailable().Returns(true);
                _logReader.TryGetRateGraphData(out result).ReturnsForAnyArgs(x =>
                {
                    x[0] = rateGraphData;
                    return true;
                });
                var all = new DashboardDataProvider(_summaryReader, _logReader).Retrieve(Option);
                var r = all[Option];

                Assert.True(r.Trend.HistoricalDataAvailable);
                Assert.Equal(rateGraphData, r.Trend.Items);
            }

            [Fact]
            public void ShouldReturnSummary()
            {
                var summary = new Summary
                {
                    InProgress = _detailBuilder.Build(),
                    Failed = _detailBuilder.Build(),
                    InError = _detailBuilder.Build(),
                    OnHold = _detailBuilder.Build(),
                    WaitingToStart = _detailBuilder.Build()
                };

                _summaryReader.Read().Returns(summary);

                var r = new DashboardDataProvider(_summaryReader, _logReader).Retrieve(Option)[Option];

                Assert.Equal(summary.Failed.Total, r.Summary.Failed.Total);
                Assert.Equal(summary.InError.Total, r.Summary.InError.Total);
                Assert.Equal(summary.OnHold.Total, r.Summary.OnHold.Total);
                Assert.Equal(summary.WaitingToStart.Total, r.Summary.WaitingToStart.Total);
                Assert.Equal(summary.InProgress.Total, r.Summary.InProgress.Total);
            }

            [Fact]
            public void ShouldReturnSummaryGroup()
            {
                var summary = new Summary
                {
                    InProgress = _detailBuilder.Build(),
                    Failed = _detailBuilder.Build(),
                    InError = _detailBuilder.Build(),
                    OnHold = _detailBuilder.Build(),
                    WaitingToStart = _detailBuilder.Build()
                };

                _summaryReader.Read().Returns(summary);

                var r = new DashboardDataProvider(_summaryReader, _logReader).Retrieve(Option)[Option];

                Assert.Equal(summary.Failed.Fresh, r.Summary.Failed.Fresh);
                Assert.Equal(summary.Failed.Tolerable, r.Summary.Failed.Tolerable);
                Assert.Equal(summary.Failed.Stuck, r.Summary.Failed.Stuck);

                Assert.Equal(summary.InError.Fresh, r.Summary.InError.Fresh);
                Assert.Equal(summary.InError.Tolerable, r.Summary.InError.Tolerable);
                Assert.Equal(summary.InError.Stuck, r.Summary.InError.Stuck);

                Assert.Equal(summary.OnHold.Fresh, r.Summary.OnHold.Fresh);
                Assert.Equal(summary.OnHold.Tolerable, r.Summary.OnHold.Tolerable);
                Assert.Equal(summary.OnHold.Stuck, r.Summary.OnHold.Stuck);

                Assert.Equal(summary.WaitingToStart.Fresh, r.Summary.WaitingToStart.Fresh);
                Assert.Equal(summary.WaitingToStart.Tolerable, r.Summary.WaitingToStart.Tolerable);
                Assert.Equal(summary.WaitingToStart.Stuck, r.Summary.WaitingToStart.Stuck);

                Assert.Equal(summary.InProgress.Fresh, r.Summary.InProgress.Fresh);
                Assert.Equal(summary.InProgress.Tolerable, r.Summary.InProgress.Tolerable);
                Assert.Equal(summary.InProgress.Stuck, r.Summary.InProgress.Stuck);
            }
        }

        public class RetrieveDefaultMethod
        {
            readonly ISummaryReader _summaryReader = Substitute.For<ISummaryReader>();
            readonly ILogReader _logReader = Substitute.For<ILogReader>();
            readonly DetailBuilder _detailBuilder = new DetailBuilder();

            const RetrieveOption Option = RetrieveOption.Default;

            [Fact]
            public void ShouldNeverReturnRateGraphData()
            {
                var rateGraphData = new List<PolicingRateItem> {new PolicingRateItem {EnterQueue = 1, ExitQueue = 1, TimeSlot = new DateTime()}};
                PolicingRateItem[] result;
                _summaryReader.Read().Returns(new Summary());
                _logReader.IsHistoricalDataAvailable().Returns(true);
                _logReader.TryGetRateGraphData(out result).ReturnsForAnyArgs(x =>
                {
                    x[0] = rateGraphData;
                    return true;
                });

                var r = new DashboardDataProvider(_summaryReader, _logReader).Retrieve(Option)[Option];

                Assert.False(r.Trend.HistoricalDataAvailable);
                Assert.Empty(r.Trend.Items);
            }

            [Fact]
            public void ShouldReturnSummary()
            {
                var summary = new Summary
                {
                    InProgress = _detailBuilder.Build(),
                    Failed = _detailBuilder.Build(),
                    InError = _detailBuilder.Build(),
                    OnHold = _detailBuilder.Build(),
                    WaitingToStart = _detailBuilder.Build()
                };

                _summaryReader.Read().Returns(summary);

                var r = new DashboardDataProvider(_summaryReader, _logReader).Retrieve(Option)[Option];

                Assert.Equal(summary.Failed.Total, r.Summary.Failed.Total);
                Assert.Equal(summary.InError.Total, r.Summary.InError.Total);
                Assert.Equal(summary.OnHold.Total, r.Summary.OnHold.Total);
                Assert.Equal(summary.WaitingToStart.Total, r.Summary.WaitingToStart.Total);
                Assert.Equal(summary.InProgress.Total, r.Summary.InProgress.Total);
            }

            [Fact]
            public void ShouldReturnSummaryGroup()
            {
                var summary = new Summary
                {
                    InProgress = _detailBuilder.Build(),
                    Failed = _detailBuilder.Build(),
                    InError = _detailBuilder.Build(),
                    OnHold = _detailBuilder.Build(),
                    WaitingToStart = _detailBuilder.Build()
                };

                _summaryReader.Read().Returns(summary);

                var r = new DashboardDataProvider(_summaryReader, _logReader).Retrieve(Option)[Option];

                Assert.Equal(summary.Failed.Fresh, r.Summary.Failed.Fresh);
                Assert.Equal(summary.Failed.Tolerable, r.Summary.Failed.Tolerable);
                Assert.Equal(summary.Failed.Stuck, r.Summary.Failed.Stuck);

                Assert.Equal(summary.InError.Fresh, r.Summary.InError.Fresh);
                Assert.Equal(summary.InError.Tolerable, r.Summary.InError.Tolerable);
                Assert.Equal(summary.InError.Stuck, r.Summary.InError.Stuck);

                Assert.Equal(summary.OnHold.Fresh, r.Summary.OnHold.Fresh);
                Assert.Equal(summary.OnHold.Tolerable, r.Summary.OnHold.Tolerable);
                Assert.Equal(summary.OnHold.Stuck, r.Summary.OnHold.Stuck);

                Assert.Equal(summary.WaitingToStart.Fresh, r.Summary.WaitingToStart.Fresh);
                Assert.Equal(summary.WaitingToStart.Tolerable, r.Summary.WaitingToStart.Tolerable);
                Assert.Equal(summary.WaitingToStart.Stuck, r.Summary.WaitingToStart.Stuck);

                Assert.Equal(summary.InProgress.Fresh, r.Summary.InProgress.Fresh);
                Assert.Equal(summary.InProgress.Tolerable, r.Summary.InProgress.Tolerable);
                Assert.Equal(summary.InProgress.Stuck, r.Summary.InProgress.Stuck);
            }
        }

        public class DetailBuilder : IBuilder<Detail>
        {
            public Detail Build()
            {
                return new Detail
                {
                    Stuck = Fixture.Integer(),
                    Fresh = Fixture.Integer(),
                    Tolerable = Fixture.Integer()
                };
            }
        }
    }
}