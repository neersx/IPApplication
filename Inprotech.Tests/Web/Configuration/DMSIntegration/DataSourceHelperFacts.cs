using System;
using Inprotech.Integration;
using Inprotech.Web.Configuration.DMSIntegration;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.DMSIntegration
{
    public class DataSourceHelperFacts
    {
        [Fact]
        public void ShouldReturnJobTypeForPrivatePair()
        {
            var r = DataSourceHelper.GetJobType(DataSourceType.UsptoPrivatePair);
            Assert.Equal(DataSourceHelper.PrivatePairJobType, r);
        }

        [Fact]
        public void ShouldReturnJobTypeForTsdr()
        {
            var r = DataSourceHelper.GetJobType(DataSourceType.UsptoTsdr);
            Assert.Equal(DataSourceHelper.TsdrJobType, r);
        }

        [Fact]
        public void ShouldThrowExceptionIfInvalidDataSource()
        {
            var e = Record.Exception(() => { DataSourceHelper.GetJobType((DataSourceType) 9); });

            Assert.IsType<InvalidOperationException>(e);
        }
    }
}