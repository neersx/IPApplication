using System.Collections.Generic;
using System.Data;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Cases.Filing;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Filing
{
    public class FilingLanguageResolverFacts : FactBase
    {
        readonly ISiteControlReader _siteControlReader = Substitute.For<ISiteControlReader>();
        readonly IDocItemRunner _docItemRunner = Substitute.For<IDocItemRunner>();

        DataSet ScalarValuedDataSet(object value)
        {
            var dataSet = new DataSet();
            var dataTable = new DataTable();
            dataTable.Columns.Add(new DataColumn());
            dataTable.Rows.Add(value);

            dataSet.Tables.Add(dataTable);
            return dataSet;
        }

        FilingLanguageResolver CreateSubject()
        {
            return new FilingLanguageResolver(Db, _siteControlReader, _docItemRunner);
        }

        [Fact]
        public void ShouldExecuteReferencedDocItem()
        {
            var valueReturned = Fixture.String();

            var docItemName = Fixture.String();

            var docItem = new DocItem
            {
                Name = docItemName
            }.In(Db);

            _siteControlReader.Read<string>(SiteControls.FilingLanguage).Returns(docItemName);
            _docItemRunner.Run(docItem.Id, Arg.Any<IDictionary<string, object>>())
                          .Returns(ScalarValuedDataSet(valueReturned));

            Assert.Equal(valueReturned, CreateSubject().Resolve(Fixture.String()));
        }

        [Fact]
        public void ShouldReturnNullIfDocItemNameNotFoundInSiteControl()
        {
            _siteControlReader.Read<string>(SiteControls.FilingLanguage).Returns(string.Empty);
            Assert.Null(CreateSubject().Resolve(Fixture.String()));
        }

        [Fact]
        public void ShouldReturnNullIfTheReferencedDocItemIsNotFound()
        {
            var docItemName = Fixture.String();
            _siteControlReader.Read<string>(SiteControls.FilingLanguage).Returns(docItemName);
            Assert.Null(CreateSubject().Resolve(Fixture.String()));
        }
    }
}