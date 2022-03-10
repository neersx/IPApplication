using System;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.DmsIntegration.Component
{
    public class NameFolderCriteriaResolverFacts : FactBase
    {
        readonly IDocItemRunner _docItemRunner = Substitute.For<IDocItemRunner>();
        readonly ISiteControlReader _siteControlReader = Substitute.For<ISiteControlReader>();

        INameFolderCriteriaResolver CreateSubject()
        {
            return new NameFolderCriteriaResolver(Db, _siteControlReader, _docItemRunner);
        }

        [Fact]
        public async Task ShouldRethrowIfNotSqlException()
        {
            var name = new NameBuilder(Db).Build().In(Db);
            var subject = CreateSubject();

            _siteControlReader.Read<string>(SiteControls.DMSNameSearchDocItem)
                              .Returns("DMS NAME SEARCH");

            _docItemRunner.WhenForAnyArgs(_ => _.Run(null, null))
                          .Throw(new Exception("bummer!"));

            var r = await Assert.ThrowsAsync<Exception>(
                                                        async () => await subject.Resolve(name.Id)
                                                       );

            Assert.IsNotType<DmsConfigurationException>(r);
        }

        [Fact]
        public async Task ShouldReturnConfigurationHintWhenDataItemExecutionFailed()
        {
            var name = new NameBuilder(Db).Build().In(Db);
            var subject = CreateSubject();

            _siteControlReader.Read<string>(SiteControls.DMSNameSearchDocItem)
                              .Returns("DMS NAME SEARCH");

            _docItemRunner.WhenForAnyArgs(_ => _.Run(null, null))
                          .Throw(new SqlExceptionBuilder().Build());

            var r = await Assert.ThrowsAsync<DmsConfigurationException>(
                                                                        async () => await subject.Resolve(name.Id)
                                                                       );

            Assert.True(r.Message.Contains("DMS NAME SEARCH"));
            Assert.True(r.Message.Contains("DMS Name Search Doc Item"));
        }

        [Fact]
        public async Task ShouldReturnNameCodeForSearching()
        {
            var name = new NameBuilder(Db).Build().In(Db);
            var subject = CreateSubject();

            var r = await subject.Resolve(name.Id);

            Assert.Equal(name.Id, r.NameEntity.NameKey);
            Assert.Equal(name.NameCode, r.NameEntity.NameCode);
            Assert.Null(r.NameEntity.NameType);
        }

        [Fact]
        public async Task ShouldReturnTransformedNameCodeViaDataItem()
        {
            var name = new NameBuilder(Db).Build().In(Db);
            var subject = CreateSubject();

            _siteControlReader.Read<string>(SiteControls.DMSNameSearchDocItem)
                              .Returns("DMS NAME SEARCH");

            _docItemRunner.Run("DMS NAME SEARCH", Arg.Any<Dictionary<string, object>>())
                          .Returns(x =>
                          {
                              var ds = new DataSet();
                              var dt = new DataTable();
                              dt.Columns.Add();
                              dt.Rows.Add("001");
                              ds.Tables.Add(dt);
                              return ds;
                          });

            var r = await subject.Resolve(name.Id);

            Assert.Equal(name.Id, r.NameEntity.NameKey);
            Assert.Equal("001", r.NameEntity.NameCode);
            Assert.Null(r.NameEntity.NameType);
        }
    }
}