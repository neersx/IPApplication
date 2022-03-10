using System;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.DmsIntegration.Component
{
    public class CaseFolderCriteriaResolverFacts : FactBase
    {
        readonly IDocItemRunner _docItemRunner = Substitute.For<IDocItemRunner>();
        readonly ISiteControlReader _siteControlReader = Substitute.For<ISiteControlReader>();

        readonly DmsSettings _settings = Substitute.For<DmsSettings>();

        ICaseFolderCriteriaResolver CreateSubject(params string[] nameTypes)
        {
            _settings.NameTypesRequired.Returns(nameTypes);
            var dmsSettingsProvider = Substitute.For<IDmsSettingsProvider>();
            dmsSettingsProvider.Provide().Returns(_settings);
            return new CaseFolderCriteriaResolver(Db, dmsSettingsProvider, _siteControlReader, _docItemRunner);
        }

        [Fact]
        public async Task ShouldRethrowIfNotSqlException()
        {
            var subject = CreateSubject();

            var r = await Assert.ThrowsAsync<InvalidOperationException>(
                                                                        async () => await subject.Resolve(Fixture.Integer())
                                                                       );

            Assert.IsNotType<DmsConfigurationException>(r);
        }

        [Fact]
        public async Task ShouldReturnCaseNameEntitiesForEachConfiguredNameTypes()
        {
            var @case = new CaseBuilder().Build().In(Db);
            new CaseNameBuilder(Db) {NameType = new NameType("I", "Instructor").In(Db)}.BuildWithCase(@case).In(Db);
            new CaseNameBuilder(Db) {NameType = new NameType("D", "Debtor").In(Db)}.BuildWithCase(@case).In(Db);
            var docitemName = "Name Search";
            var nameCode = "10001";

            _siteControlReader.Read<string>(SiteControls.DMSNameSearchDocItem).Returns(docitemName);
            _docItemRunner.Run(docitemName, Arg.Any<Dictionary<string, object>>())
                          .Returns(x =>
                          {
                              var ds = new DataSet();
                              var dt = new DataTable();
                              dt.Columns.Add();
                              dt.Rows.Add(nameCode);
                              ds.Tables.Add(dt);
                              return ds;
                          });

            var subject = CreateSubject("I", "D");

            var r = await subject.Resolve(@case.Id);

            Assert.Equal(@case.Id, r.CaseKey);
            Assert.Equal(@case.Irn, r.CaseReference);
            Assert.Contains(r.CaseNameEntities, x => x.NameType == "I" && x.NameCode == nameCode);
            Assert.Contains(r.CaseNameEntities, x => x.NameType == "D" && x.NameCode == nameCode);
        }

        [Fact]
        public async Task ShouldReturnCaseNameEntitiesForEachConfiguredNameTypesFromDmsNameTypesSiteControl()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var cnInstructor = new CaseNameBuilder(Db) {NameType = new NameType("I", "Instructor").In(Db)}.BuildWithCase(@case).In(Db);
            var cnDebtor = new CaseNameBuilder(Db) {NameType = new NameType("D", "Debtor").In(Db)}.BuildWithCase(@case).In(Db);

            _siteControlReader.Read<string>(SiteControls.DMSNameTypes)
                              .Returns("I,D");

            var subject = CreateSubject();

            var r = await subject.Resolve(@case.Id);

            Assert.Equal(@case.Id, r.CaseKey);
            Assert.Equal(@case.Irn, r.CaseReference);
            Assert.Contains(r.CaseNameEntities, x => x.NameType == "I" && x.NameCode == cnInstructor.Name.NameCode);
            Assert.Contains(r.CaseNameEntities, x => x.NameType == "D" && x.NameCode == cnDebtor.Name.NameCode);
        }

        [Fact]
        public async Task ShouldReturnCaseRefForSearching()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var subject = CreateSubject();

            var r = await subject.Resolve(@case.Id);

            Assert.Equal(@case.Id, r.CaseKey);
            Assert.Equal(@case.Irn, r.CaseReference);
            Assert.Empty(r.CaseNameEntities);
        }

        [Fact]
        public async Task ShouldReturnConfigurationHintWhenDataItemExecutionFailed()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var subject = CreateSubject();

            _siteControlReader.Read<string>(SiteControls.DMSCaseSearchDocItem)
                              .Returns("DMS CASE SEARCH");

            _docItemRunner.WhenForAnyArgs(_ => _.Run(null, null))
                          .Throw(new SqlExceptionBuilder().Build());

            var r = await Assert.ThrowsAsync<DmsConfigurationException>(
                                                                        async () => await subject.Resolve(@case.Id)
                                                                       );

            Assert.True(r.Message.Contains("DMS CASE SEARCH"));
            Assert.True(r.Message.Contains("DMS Case Search Doc Item"));
        }

        [Fact]
        public async Task ShouldReturnTransformedCaseRefViaDataItem()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var subject = CreateSubject();

            _siteControlReader.Read<string>(SiteControls.DMSCaseSearchDocItem)
                              .Returns("DMS CASE SEARCH");

            _docItemRunner.Run("DMS CASE SEARCH", Arg.Any<Dictionary<string, object>>())
                          .Returns(x =>
                          {
                              var ds = new DataSet();
                              var dt = new DataTable();
                              dt.Columns.Add();
                              dt.Rows.Add("001");
                              ds.Tables.Add(dt);
                              return ds;
                          });

            var r = await subject.Resolve(@case.Id);

            Assert.Equal(@case.Id, r.CaseKey);
            Assert.Equal("001", r.CaseReference);
            Assert.Empty(r.CaseNameEntities);
        }
    }
}