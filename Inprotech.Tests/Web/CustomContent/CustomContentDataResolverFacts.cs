using System;
using System.Collections.Generic;
using System.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.CustomContent;
using InprotechKaizen.Model.Components.DocumentGeneration.Processor;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.CustomContent
{
    public class CustomContentDataResolverFacts : FactBase
    {
        public class CustomContentDataResolverFixture : IFixture<CustomContentDataResolver>
        {
            public CustomContentDataResolverFixture(InMemoryDbContext db)
            {
                DbContext = db;
                LegacyDocItemRunner = Substitute.For<ILegacyDocItemRunner>();

                Subject = new CustomContentDataResolver(DbContext, LegacyDocItemRunner);
            }

            public ILegacyDocItemRunner LegacyDocItemRunner { get; set; }

            public InMemoryDbContext DbContext { get; }

            public CustomContentDataResolver Subject { get; }
        }

        public class ResolveMethod : FactBase
        {
            public DocItem GetDocItem()
            {
                return new DocItem {Id = Fixture.Integer(), Name = Fixture.String()}.In(Db);
            }

            public CustomContentDataResolverFixture Setup(string url, string title, string className)
            {
                var values = new List<object> {url, title, className};

                var resultSet = new List<TableResultSet> {new TableResultSet {RowResultSets = new List<RowResultSet> {new RowResultSet {Values = values}}}};

                var f = new CustomContentDataResolverFixture(Db);

                f.LegacyDocItemRunner.Execute(
                                              Arg.Any<ReferencedDataItem>(),
                                              Arg.Any<string>(),
                                              Arg.Any<string>(),
                                              Arg.Any<RowsReturnedMode>()).Returns(resultSet);
                return f;
            }

            [Fact]
            public void ShouldThrowExceptionIfWrongExternalApplicationIdIsProvided()
            {
                var exception =
                    Record.Exception(() => { new CustomContentDataResolverFixture(Db).Subject.Resolve(Fixture.Integer(), Fixture.String()); });

                Assert.IsType<ArgumentException>(exception);
                Assert.Equal("Invalid DocItem", exception.Message);
            }

            [Fact]
            public void ReturnCustomContentData()
            {
                var item = GetDocItem();

                var f = Setup("http://google.com", "Title", "ClassName");

                var result = f.Subject.Resolve(item.Id, "1");
                
                f.LegacyDocItemRunner.Received(1).Execute(
                                                          Arg.Any<ReferencedDataItem>(),
                                                          string.Empty,
                                                          "1",
                                                          RowsReturnedMode.Single);

                Assert.Equal(result.CustomUrl, HttpUtility.UrlEncode("http://google.com"));
                Assert.Equal(result.Title, "Title");
                Assert.Equal(result.ClassName, "ClassName");
            }

            [Fact]
            public void ReturnUrlAsBlankIfItIsNotAValidUrl()
            {
                var item = GetDocItem();

                var f = Setup("a", "Title", string.Empty);

                var result = f.Subject.Resolve(item.Id, "1");

                Assert.Equal(result.CustomUrl, string.Empty);
                Assert.Equal(result.Title, "Title");
                Assert.Equal(result.ClassName, string.Empty);
            }

            [Fact]
            public void ReturnOnlyUrlIfOtherDetailsAreNotReturnedFromDocItem()
            {
                var item = GetDocItem();

                var f = Setup("http://google.com", string.Empty, string.Empty);

                var result = f.Subject.Resolve(item.Id, "1");

                Assert.Equal(result.CustomUrl, HttpUtility.UrlEncode("http://google.com"));
                Assert.Equal(result.Title, string.Empty);
                Assert.Equal(result.ClassName, string.Empty);
            }
        }
    }
}