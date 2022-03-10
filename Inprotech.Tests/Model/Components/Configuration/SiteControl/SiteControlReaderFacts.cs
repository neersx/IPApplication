using System;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using Xunit;
using Model = InprotechKaizen.Model.Configuration.SiteControl;

namespace Inprotech.Tests.Model.Components.Configuration.SiteControl
{
    public class SiteControlReaderFacts : FactBase
    {
        public SiteControlReaderFacts()
        {
            _siteControlReader = new SiteControlReader(Db, new SiteControlCache());
        }

        readonly ISiteControlReader _siteControlReader;

        [Fact]
        public void ShouldReadBoolean()
        {
            new InprotechKaizen.Model.Configuration.SiteControl.SiteControl("Date Style", true).In(Db);
            var r = _siteControlReader.Read<bool>(SiteControls.DateStyle);
            Assert.True(r);
        }

        [Fact]
        public void ShouldReadDecimal()
        {
            new InprotechKaizen.Model.Configuration.SiteControl.SiteControl("Date Style", (decimal) 1.0).In(Db);
            var r = _siteControlReader.Read<decimal>(SiteControls.DateStyle);
            Assert.Equal((decimal) 1.0, r);
        }

        [Fact]
        public void ShouldReadInteger()
        {
            new InprotechKaizen.Model.Configuration.SiteControl.SiteControl("Date Style", 1).In(Db);
            var r = _siteControlReader.Read<int>(SiteControls.DateStyle);
            Assert.Equal(1, r);
        }

        [Fact]
        public void ShouldReadNull()
        {
            new InprotechKaizen.Model.Configuration.SiteControl.SiteControl("Date Style").In(Db);
            Assert.Null(_siteControlReader.Read<int?>(SiteControls.DateStyle));
            Assert.Null(_siteControlReader.Read<bool?>(SiteControls.DateStyle));
            Assert.Null(_siteControlReader.Read<decimal?>(SiteControls.DateStyle));
            Assert.Null(_siteControlReader.Read<string>(SiteControls.DateStyle));
            Assert.Null(_siteControlReader.Read<DateTime?>(SiteControls.DateStyle));
        }

        [Fact]
        public void ShouldReadNullableDateTime()
        {
            new InprotechKaizen.Model.Configuration.SiteControl.SiteControl("Date Style", DateTime.Parse("2000-01-02")).In(Db);
            var r = _siteControlReader.Read<DateTime?>(SiteControls.DateStyle);
            Assert.Equal(DateTime.Parse("2000-01-02"), r);
        }

        [Fact]
        public void ShouldReadNullableDecimal()
        {
            new InprotechKaizen.Model.Configuration.SiteControl.SiteControl("Date Style", (decimal) 1.0).In(Db);
            var r = _siteControlReader.Read<decimal?>(SiteControls.DateStyle);
            Assert.Equal((decimal) 1.0, r);
        }

        [Fact]
        public void ShouldReadNullableInteger()
        {
            new InprotechKaizen.Model.Configuration.SiteControl.SiteControl("Date Style", 1).In(Db);
            var r = _siteControlReader.Read<int?>(SiteControls.DateStyle);
            Assert.Equal(1, r);
        }

        [Fact]
        public void ShouldReadNullalbleBoolean()
        {
            new InprotechKaizen.Model.Configuration.SiteControl.SiteControl("Date Style", true).In(Db);
            var r = _siteControlReader.Read<bool?>(SiteControls.DateStyle);
            Assert.Equal(true, r);
        }

        [Fact]
        public void ShouldReadString()
        {
            new InprotechKaizen.Model.Configuration.SiteControl.SiteControl("Date Style", "s").In(Db);
            var r = _siteControlReader.Read<string>(SiteControls.DateStyle);
            Assert.Equal("s", r);
        }
    }
}